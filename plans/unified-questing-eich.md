# 结直肠癌DFS预测项目 - 完整实施计划

## 📋 项目概要

**目标**: 基于多时相CT影像预测结直肠癌无病生存期(DFS)，二分类任务（≥24月 vs <24月）

**数据规模**:
- 患者样本：361例（DCB 247例 68% / non-DCB 114例 32%）
- CT期相：AP/VP/DP/NP（4期，349例完整）
- 临床特征：18个（性别、年龄、肿瘤大小、病理分级等）
- PyRadiomics特征：每期~1130维

**技术路线**:
- **Track 1**: 影像组学 + 传统ML（XGBoost/RF/LightGBM）
- **Track 2**: 深度学习CNN（2.5D/3D/ResNet3D）
- **Track 3**: 多模态融合（Radiomics + CNN + Clinical）

**用户确认需求**:
- ✅ 使用全部361个样本
- ✅ 使用所有4期影像（AP/VP/DP/NP）
- ✅ CNN对比多种架构（2.5D、3D、ResNet3D）
- ✅ 优先Track 1 → Track 2 → Track 3

---

## 🎯 预期成果

### 性能目标
| Track | 方法 | 预期AUC | 关键产出 |
|-------|------|---------|---------|
| Track 1 | 影像组学+XGBoost | 0.70-0.78 | 特征重要性、相关性分析 |
| Track 2 | ResNet3D | 0.75-0.82 | CNN特征、架构对比 |
| Track 3 | 多模态融合 | 0.80-0.88 | 消融实验、最佳模型 |

### 可视化产出（50+张图表）
- ✅ ROC曲线（每个实验 + Track对比）
- ✅ 决策曲线分析DCA（临床净收益评估）
- ✅ 校准曲线（预测概率可靠性）
- ✅ 特征相关性热图（与DFS关联分析）
- ✅ 性能汇总表（Markdown + PNG）
- ✅ 消融实验图（模态贡献分析）

---

## ⏱️ 时间规划（总计59-85小时，约3-4天）

| 阶段 | 任务 | 时间 | 依赖 |
|-----|------|------|------|
| **Day 1-2** | 数据准备 + Track 1 | 21-26h | - |
| **Day 3-4** | Track 2 (CNN) | 25-40h | Day 1完成 |
| **Day 5-6** | Track 3 (融合) | 25-40h | Day 4完成 |
| **Day 7** | 综合评估与报告 | 5-6h | All完成 |

**关键里程碑**:
- 🏁 Day 2末：VP特征提取完成，Track 1基线AUC>0.65
- 🏁 Day 4末：2.5D CNN完成，CNN特征提取完成
- 🏁 Day 6末：Track 3融合模型完成，AUC>0.78
- 🏁 Day 7末：综合报告交付

---

## 📂 阶段1: 数据准备与特征提取（16-20小时）

### 任务1.1: 数据完整性验证（10分钟）

**创建脚本**: `scripts/verify_data_completeness.py`

**功能**:
- 遍历361个患者文件夹，检查4期影像和分割文件完整性
- 统计每期可用率（预期VP 99.2%, AP 97.2%, DP 97.5%, NP 98.3%）
- 生成数据质量报告CSV

**执行命令**:
```bash
python scripts/verify_data_completeness.py \
    --data_dir data/new \
    --metadata data/new/CRC_ldey_Revision.xlsx \
    --output data/new/data_quality_report.csv
```

**预期输出**:
- `data_quality_report.csv`: 每个患者的期相完整性统计
- 终端打印：总体统计摘要

---

### 任务1.2: PyRadiomics特征提取（15-19小时）

**现有脚本**: `src/radilearn/features/extract_dfs_features.py` ✅ 已实现

#### 子任务A: VP单期提取（3-4小时）
优先提取VP期以便Track 1快速启动

```bash
PYTHONPATH=src python src/radilearn/features/extract_dfs_features.py \
    --data_dir data/new \
    --metadata data/new/CRC_ldey_Revision.xlsx \
    --output data/new/features_VP.csv \
    --phases VP \
    --n_jobs 8 \
    --dfs_threshold 24.0
```

**输出**: `features_VP.csv` (358行 × 1153列)
- patient_id, dfs, label (3列)
- 临床特征 (18列)
- VP_radiomics特征 (~1130列): shape, firstorder, glcm, wavelet等

#### 子任务B: 全4期提取（12-15小时，后台运行）
```bash
# 使用nohup后台运行
nohup PYTHONPATH=src python src/radilearn/features/extract_dfs_features.py \
    --data_dir data/new \
    --metadata data/new/CRC_ldey_Revision.xlsx \
    --output data/new/features_all_phases.csv \
    --phases AP VP DP NP \
    --n_jobs 16 \
    > logs/feature_extraction_all.log 2>&1 &

# 监控进度
tail -f logs/feature_extraction_all.log
```

**输出**: `features_all_phases.csv` (349行 × 4543列)
- 4期完整的radiomics特征（AP/VP/DP/NP各1130维）

**优化策略**:
- 使用最大CPU核心数（`--n_jobs 16`）
- VP期提取完成后立即启动Track 1，无需等待4期全部完成
- 4期提取在后台运行，供Track 1多期相实验和Track 2/3使用

---

### 任务1.3: 数据集划分（30分钟）

**创建脚本**: `scripts/create_data_splits.py`

**功能**:
- 5折分层交叉验证划分（主要评估方式）
- 70/15/15固定划分（用于最终测试集保留）
- 保持类别平衡（DCB:non-DCB ≈ 2:1）

```bash
python scripts/create_data_splits.py \
    --features data/new/features_VP.csv \
    --output data/new/data_splits.json \
    --val_ratio 0.15 \
    --test_ratio 0.15 \
    --random_seed 42
```

**输出**: `data_splits.json`
```json
{
  "cv_folds": [
    {"train": [...], "val": [...]},
    ...
  ],
  "fixed_split": {
    "train": [...], "val": [...], "test": [...]
  },
  "stats": {
    "train": {"total": 253, "DCB": 173, "non-DCB": 80},
    "val": {"total": 54, "DCB": 37, "non-DCB": 17},
    "test": {"total": 54, "DCB": 37, "non-DCB": 17}
  }
}
```

---

## 📊 阶段2: Track 1 - 影像组学+传统ML（5-6小时）

### 任务2.1: 基线实验 - VP单期（30分钟）

**修改文件**: `experiments/dfs_prediction/track1/train_radiomics.py`

**需要增强**（在main()函数末尾添加）:
```python
# 1. DCA决策曲线
from radilearn.evaluation.dca import decision_curve_analysis, plot_decision_curve
dca_results = decision_curve_analysis(y_true_all, roc_data)
plot_decision_curve(dca_results, save_path=output_dir / f"{exp_name}_dca.png")

# 2. 校准曲线
from radilearn.evaluation.calibration import plot_calibration_curve
plot_calibration_curve(y_true_all, roc_data, save_path=output_dir / f"{exp_name}_calibration.png")

# 3. 特征相关性热图
correlation_matrix = pd.DataFrame(X_selected, columns=selected_names).corr()
top_features = feature_importance.nlargest(50).index
plt.figure(figsize=(12, 10))
sns.heatmap(correlation_matrix.loc[top_features, top_features],
            cmap='coolwarm', center=0, annot=False)
plt.savefig(output_dir / f"{exp_name}_feature_correlation.png", dpi=300)
```

**执行命令**:
```bash
PYTHONPATH=src python experiments/dfs_prediction/track1/train_radiomics.py \
    --features data/new/features_VP.csv \
    --output_dir experiments/dfs_prediction/track1/results \
    --exp_name TUNE_1_baseline_VP \
    --feature_selection variance \
    --n_features 100 \
    --cv_folds 5 \
    --use_smote
```

**预期输出**:
```
track1/results/TUNE_1_baseline_VP/
├── TUNE_1_baseline_VP_log.json                      # 配置和CV结果
├── TUNE_1_baseline_VP_roc_curves.png                # ROC对比图
├── TUNE_1_baseline_VP_dca.png                       # [新增] DCA决策曲线
├── TUNE_1_baseline_VP_calibration.png               # [新增] 校准曲线
├── TUNE_1_baseline_VP_feature_correlation.png       # [新增] 特征相关性热图
├── TUNE_1_baseline_VP_XGBoost_model.joblib          # 训练好的模型
├── TUNE_1_baseline_VP_XGBoost_feature_importance.png
├── TUNE_1_baseline_VP_RandomForest_model.joblib
└── TUNE_1_baseline_VP_LightGBM_model.joblib
```

**预期性能**:
- XGBoost AUC: 0.68-0.75
- RandomForest AUC: 0.65-0.72
- LightGBM AUC: 0.67-0.74

---

### 任务2.2: 特征选择对比（1.5小时）

**实验设计**:
| 实验ID | 特征选择方法 | 特征数 | 目的 |
|--------|-------------|--------|------|
| TUNE_2 | variance | 50 | 评估少量特征效果 |
| TUNE_3 | variance | 150 | 评估更多特征效果 |
| TUNE_4 | kbest | 100 | 对比不同选择方法 |

**执行命令**（可并行运行）:
```bash
# 方差法-50特征
PYTHONPATH=src python experiments/dfs_prediction/track1/train_radiomics.py \
    --features data/new/features_VP.csv \
    --exp_name TUNE_2_variance_50 \
    --feature_selection variance \
    --n_features 50 &

# 方差法-150特征
PYTHONPATH=src python experiments/dfs_prediction/track1/train_radiomics.py \
    --exp_name TUNE_3_variance_150 \
    --feature_selection variance \
    --n_features 150 &

# KBest-100特征
PYTHONPATH=src python experiments/dfs_prediction/track1/train_radiomics.py \
    --exp_name TUNE_4_kbest_100 \
    --feature_selection kbest \
    --n_features 100 &

wait  # 等待所有后台任务完成
```

---

### 任务2.3: 多期相特征融合（2小时）

**创建脚本**: `experiments/dfs_prediction/track1/train_multiphase_radiomics.py`

**融合策略**:
1. **Concatenation**: 直接拼接4期特征 [AP, VP, DP, NP] → 4520维
2. **Difference**: VP + 差异特征 [VP, VP-AP, VP-DP, VP-NP] → 1130×4维
3. **Per-phase selection**: 每期独立选择top50后拼接 → 200维

**核心代码片段**:
```python
def fuse_multiphase_features(df, strategy='concat', n_per_phase=50):
    if strategy == 'concat':
        # 提取4期所有特征列
        ap_cols = [c for c in df.columns if c.startswith('AP_original')]
        vp_cols = [c for c in df.columns if c.startswith('VP_original')]
        dp_cols = [c for c in df.columns if c.startswith('DP_original')]
        np_cols = [c for c in df.columns if c.startswith('NP_original')]
        X = df[ap_cols + vp_cols + dp_cols + np_cols].values

    elif strategy == 'difference':
        # 计算期相差异
        vp_features = df[vp_cols].values
        diff_ap = vp_features - df[ap_cols].values
        diff_dp = vp_features - df[dp_cols].values
        diff_np = vp_features - df[np_cols].values
        X = np.hstack([vp_features, diff_ap, diff_dp, diff_np])

    elif strategy == 'per_phase_selection':
        # 每期独立选择重要特征
        X_list = []
        for phase in ['AP', 'VP', 'DP', 'NP']:
            phase_cols = [c for c in df.columns if c.startswith(f'{phase}_')]
            X_phase = df[phase_cols].values
            # 方差选择top N
            selector = VarianceThreshold()
            X_phase = selector.fit_transform(X_phase)
            top_indices = np.argsort(np.var(X_phase, axis=0))[-n_per_phase:]
            X_list.append(X_phase[:, top_indices])
        X = np.hstack(X_list)

    return X
```

**执行命令**（需等待4期特征提取完成）:
```bash
# 早期融合（拼接）
PYTHONPATH=src python experiments/dfs_prediction/track1/train_multiphase_radiomics.py \
    --features data/new/features_all_phases.csv \
    --exp_name TUNE_5_multiphase_concat \
    --fusion_strategy concat \
    --feature_selection variance \
    --n_features 200

# 差异特征
PYTHONPATH=src python experiments/dfs_prediction/track1/train_multiphase_radiomics.py \
    --exp_name TUNE_6_multiphase_diff \
    --fusion_strategy difference \
    --n_features 200
```

**预期提升**: 多期相融合AUC 0.72-0.80（比单期提升5-10%）

---

### 任务2.4: Track 1综合可视化与特征分析（1.5小时）

**创建脚本**: `experiments/dfs_prediction/track1/visualize_track1.py`

**核心功能**:
1. 汇总所有Track 1实验结果（TUNE_1到TUNE_6）
2. 绘制综合ROC/DCA/校准曲线对比
3. **特征-DFS相关性分析**（Mann-Whitney U检验）
4. 生成性能汇总表（Markdown + PNG）

**特征相关性分析代码**:
```python
from scipy.stats import mannwhitneyu, spearmanr

def analyze_dfs_correlation(features_df):
    """分析特征与DFS的关联性"""
    radiomics_cols = [c for c in features_df.columns
                      if c.startswith('VP_original')]

    dcb_mask = features_df['label'] == 0
    non_dcb_mask = features_df['label'] == 1

    results = []
    for col in radiomics_cols:
        dcb_values = features_df.loc[dcb_mask, col].dropna()
        non_dcb_values = features_df.loc[non_dcb_mask, col].dropna()

        # Mann-Whitney U检验
        stat, pvalue = mannwhitneyu(dcb_values, non_dcb_values, alternative='two-sided')

        # Spearman相关系数
        corr, _ = spearmanr(features_df[col], features_df['label'])

        results.append({
            'feature': col,
            'pvalue': pvalue,
            'correlation': corr,
            'dcb_mean': dcb_values.mean(),
            'non_dcb_mean': non_dcb_values.mean(),
            'effect_size': (non_dcb_values.mean() - dcb_values.mean()) / dcb_values.std()
        })

    df_results = pd.DataFrame(results).sort_values('pvalue')
    significant = df_results[df_results['pvalue'] < 0.05]

    return df_results, significant
```

**执行命令**:
```bash
PYTHONPATH=src python experiments/dfs_prediction/track1/visualize_track1.py \
    --results_dir experiments/dfs_prediction/track1/results \
    --features data/new/features_VP.csv \
    --output_dir experiments/dfs_prediction/track1/visualizations
```

**输出**:
```
track1/visualizations/
├── combined_roc.png                      # 所有实验ROC对比
├── combined_dca.png                      # DCA对比
├── combined_calibration.png              # 校准曲线对比
├── feature_correlation_heatmap.png       # Top 50特征相关性
├── dfs_associated_features.csv           # 显著特征列表(p<0.05)
├── top20_feature_boxplots.png            # Top 20特征箱线图
└── performance_summary.md                # 性能汇总表
```

**性能汇总表示例**:
```markdown
| Experiment | Method | #Features | AUC | Accuracy | Sensitivity | Specificity |
|------------|--------|-----------|-----|----------|-------------|-------------|
| TUNE_1 | Variance-100 | 100 | 0.712±0.083 | 0.684±0.071 | 0.645±0.092 | 0.702±0.088 |
| TUNE_3 | Variance-150 | 150 | 0.738±0.076 | 0.701±0.065 | 0.672±0.084 | 0.718±0.081 |
| TUNE_5 | Multiphase | 200 | **0.769±0.071** | **0.723±0.059** | 0.701±0.079 | **0.735±0.075** |
```

---

## 🧠 阶段3: Track 2 - 深度学习CNN（40-60小时，并行20-30小时）

### 任务3.1: 2.5D CNN基线（4-6小时）

**修改文件**: `experiments/dfs_prediction/track2/train_cnn.py`

**需要增强**: 数据增强模块（在`DFSImageDataset`类中）

```python
class DFSImageDataset(Dataset):
    def __init__(self, ..., augment=False):
        self.augment = augment

    def _apply_augmentation(self, image):
        """随机应用数据增强"""
        if np.random.rand() > 0.5:
            # 旋转 ±15度
            angle = np.random.uniform(-15, 15)
            image = self._rotate(image, angle)

        if np.random.rand() > 0.5:
            # 水平翻转
            image = np.flip(image, axis=-1).copy()

        if np.random.rand() > 0.5:
            # 强度扰动 ±10%
            image = image * np.random.uniform(0.9, 1.1)

        return image

    def __getitem__(self, idx):
        ...
        if self.augment and self.is_training:
            image = self._apply_augmentation(image)
        ...
```

**执行命令**:
```bash
# 单期VP
PYTHONPATH=src python experiments/dfs_prediction/track2/train_cnn.py \
    --data_dir data/new \
    --metadata data/new/CRC_ldey_Revision.xlsx \
    --phases VP \
    --model_type 2.5d \
    --epochs 100 \
    --batch_size 16 \
    --learning_rate 1e-4 \
    --augment \
    --exp_name CNN_1_2.5D_VP \
    --output_dir experiments/dfs_prediction/track2/results

# 4期融合（早期融合：20通道输入）
PYTHONPATH=src python experiments/dfs_prediction/track2/train_cnn.py \
    --phases AP VP DP NP \
    --model_type 2.5d \
    --epochs 100 \
    --batch_size 8 \
    --augment \
    --exp_name CNN_2_2.5D_all_phases
```

**预期性能**:
- 单期VP: AUC 0.72-0.78
- 4期融合: AUC 0.75-0.81

**训练时间**（Apple M2 Max MPS）:
- 单期: 4-5小时
- 4期: 5-7小时

---

### 任务3.2: 3D CNN实验（12-18小时）

**执行命令**:
```bash
# 3D CNN - VP期
PYTHONPATH=src python experiments/dfs_prediction/track2/train_cnn.py \
    --phases VP \
    --model_type 3d \
    --epochs 100 \
    --batch_size 4 \
    --learning_rate 1e-4 \
    --augment \
    --exp_name CNN_3_3D_VP &

# 3D CNN - 4期融合
PYTHONPATH=src python experiments/dfs_prediction/track2/train_cnn.py \
    --phases AP VP DP NP \
    --model_type 3d \
    --epochs 100 \
    --batch_size 2 \
    --gradient_accumulation_steps 2 \
    --augment \
    --exp_name CNN_4_3D_all_phases &
```

**关键配置**:
- 输入尺寸: `(B, C, D, H, W)` = `(2, 4, 32, 128, 128)`
- 显存需求: ~6-8GB per sample
- 使用梯度累积模拟更大batch size

**预期性能**: 3D CNN AUC 0.74-0.82

---

### 任务3.3: ResNet3D训练（8-12小时）

**创建脚本**: `experiments/dfs_prediction/track2/train_resnet3d.py`
（基于`train_cnn.py`修改，添加Med3D预训练支持）

**核心修改**:
```python
# 创建ResNet3D模型
model = ResNet3D(
    in_channels=len(phases),
    num_classes=2,
    layers=[2, 2, 2, 2],  # ResNet-18
    dropout=0.5,
).to(device)

# 可选：加载Med3D预训练权重
if args.pretrained and Path('pretrained/med3d_resnet18.pth').exists():
    pretrained_dict = torch.load('pretrained/med3d_resnet18.pth')
    # 仅加载匹配的层
    model_dict = model.state_dict()
    pretrained_dict = {k: v for k, v in pretrained_dict.items()
                       if k in model_dict and v.shape == model_dict[k].shape}
    model.load_state_dict(pretrained_dict, strict=False)

    # 微调策略：冻结前N层
    for name, param in model.named_parameters():
        if 'layer4' not in name and 'fc' not in name:
            param.requires_grad = False
```

**执行命令**:
```bash
# 从零训练
PYTHONPATH=src python experiments/dfs_prediction/track2/train_resnet3d.py \
    --phases VP \
    --model_type resnet3d \
    --epochs 100 \
    --batch_size 4 \
    --augment \
    --exp_name CNN_5_ResNet3D_scratch

# 使用预训练（如可用）
PYTHONPATH=src python experiments/dfs_prediction/track2/train_resnet3d.py \
    --phases VP \
    --model_type resnet3d \
    --pretrained \
    --freeze_layers 10 \
    --epochs 50 \
    --learning_rate 5e-5 \
    --augment \
    --exp_name CNN_6_ResNet3D_pretrained
```

**Med3D预训练**:
- 下载：https://github.com/Tencent/MedicalNet
- 如不可用，仅使用从零训练版本

**预期性能**:
- From scratch: AUC 0.76-0.82
- Pretrained: AUC 0.78-0.84 (+2-3%)

---

### 任务3.4: CNN深度特征提取（30分钟）

**创建脚本**: `experiments/dfs_prediction/track2/extract_cnn_features.py`

**功能**: 加载最佳CNN模型，提取倒数第二层特征（512维）供Track 3使用

**核心代码**:
```python
def extract_cnn_features(model_path, dataloader, device):
    model = torch.load(model_path).to(device)
    model.eval()

    all_features = []
    all_patient_ids = []

    with torch.no_grad():
        for batch_x, patient_ids in dataloader:
            features = model.get_features(batch_x.to(device))  # [B, 512]
            all_features.append(features.cpu().numpy())
            all_patient_ids.extend(patient_ids)

    features_array = np.vstack(all_features)
    df = pd.DataFrame(features_array,
                      columns=[f'cnn_feat_{i}' for i in range(512)])
    df.insert(0, 'patient_id', all_patient_ids)
    return df
```

**执行命令**:
```bash
# 提取VP期CNN特征
PYTHONPATH=src python experiments/dfs_prediction/track2/extract_cnn_features.py \
    --data_dir data/new \
    --metadata data/new/CRC_ldey_Revision.xlsx \
    --model_checkpoint experiments/dfs_prediction/track2/results/CNN_1_2.5D_VP/model_fold1.pt \
    --model_type 2.5d \
    --phases VP \
    --output data/new/cnn_features_VP.csv

# 提取4期CNN特征
PYTHONPATH=src python experiments/dfs_prediction/track2/extract_cnn_features.py \
    --model_checkpoint experiments/dfs_prediction/track2/results/CNN_2_2.5D_all_phases/model_fold1.pt \
    --phases AP VP DP NP \
    --output data/new/cnn_features_all_phases.csv
```

**输出**:
- `cnn_features_VP.csv` (358行 × 513列)
- `cnn_features_all_phases.csv` (349行 × 513列)

---

### 任务3.5: Track 2综合可视化（2小时）

**创建脚本**: `experiments/dfs_prediction/track2/visualize_track2.py`

**功能**:
- 汇总所有CNN实验（CNN_1到CNN_6）
- 绘制架构对比ROC/DCA/校准曲线
- 生成性能对比表

```bash
PYTHONPATH=src python experiments/dfs_prediction/track2/visualize_track2.py \
    --results_dir experiments/dfs_prediction/track2/results \
    --output_dir experiments/dfs_prediction/track2/visualizations
```

**输出**:
```
track2/visualizations/
├── model_comparison_roc.png
├── model_comparison_dca.png
├── model_comparison_calibration.png
├── architecture_comparison.md
└── confusion_matrices.png
```

---

## 🔗 阶段4: Track 3 - 多模态融合（25-40小时，并行15-25小时）

### 任务4.1: 基线融合模型（6-10小时）

**现有脚本**: `experiments/dfs_prediction/track3/train_fusion.py` ✅ 已实现

**执行4种融合方法**:

```bash
# 1. Concatenation（简单拼接）
PYTHONPATH=src python experiments/dfs_prediction/track3/train_fusion.py \
    --radiomics_features data/new/features_VP.csv \
    --cnn_features data/new/cnn_features_VP.csv \
    --fusion_method concat \
    --epochs 150 \
    --batch_size 32 \
    --learning_rate 1e-3 \
    --exp_name FUSION_1_concat &

# 2. Gated Fusion（门控融合）
PYTHONPATH=src python experiments/dfs_prediction/track3/train_fusion.py \
    --fusion_method gated \
    --exp_name FUSION_2_gated &

# 3. Attention Fusion（注意力融合）
PYTHONPATH=src python experiments/dfs_prediction/track3/train_fusion.py \
    --fusion_method attention \
    --exp_name FUSION_3_attention &

# 4. Hierarchical Fusion（层次融合）
PYTHONPATH=src python experiments/dfs_prediction/track3/train_fusion.py \
    --fusion_method hierarchical \
    --exp_name FUSION_4_hierarchical &

wait
```

**预期性能**:
| 融合方法 | AUC | 特点 |
|---------|-----|------|
| Concat | 0.78-0.82 | 简单有效 |
| Gated | 0.80-0.84 | 学习权重 |
| Attention | 0.81-0.85 | 动态关注 |
| Hierarchical | 0.82-0.86 | 层次建模 |

---

### 任务4.2: 消融实验（8-12小时）

**目的**: 评估每种模态（Radiomics、CNN、Clinical）的贡献

**执行命令**:
```bash
PYTHONPATH=src python experiments/dfs_prediction/track3/train_fusion.py \
    --radiomics_features data/new/features_VP.csv \
    --cnn_features data/new/cnn_features_VP.csv \
    --ablation \
    --output_dir experiments/dfs_prediction/track3/results
```

**自动运行7个配置**:
1. Radiomics only
2. CNN only
3. Clinical only
4. Radiomics + Clinical
5. Radiomics + CNN
6. CNN + Clinical
7. All modalities（完整模型）

**预期输出**: `ablation_summary.csv`
```csv
Ablation,AUC,Accuracy,F1,Brier
radiomics_only,0.712,0.684,0.701,0.243
cnn_only,0.745,0.708,0.725,0.231
clinical_only,0.623,0.592,0.605,0.287
radiomics_clinical,0.728,0.695,0.712,0.238
radiomics_cnn,0.801,0.761,0.778,0.214
cnn_clinical,0.758,0.721,0.738,0.226
all_modalities,0.823,0.781,0.795,0.206
```

**关键发现**（预期）:
- Radiomics + CNN协同效应最强（+10% AUC vs 单模态）
- CNN特征提供空间语义信息，与Radiomics互补
- Clinical特征单独效果较弱，但与其他模态结合有增益

---

### 任务4.3: 多期相多模态融合（10-15小时）

**创建脚本**: `experiments/dfs_prediction/track3/train_multiphase_fusion.py`

**融合架构**:
```
输入:
├─ 4期Radiomics: AP(1130) + VP(1130) + DP(1130) + NP(1130) = 4520维
├─ 4期CNN特征: AP(512) + VP(512) + DP(512) + NP(512) = 2048维
└─ Clinical: 18维
总计: 6586维

网络结构:
Layer 1: 分模态编码
├─ Radiomics Encoder: 4520 → 256 (FC + BatchNorm + ReLU + Dropout)
├─ CNN Encoder: 2048 → 256
└─ Clinical Encoder: 18 → 64

Layer 2: 层次注意力融合
└─ Hierarchical Attention: [256, 256, 64] → 512

Layer 3: 分类器
└─ FC: 512 → 128 → 2
```

**执行命令**:
```bash
PYTHONPATH=src python experiments/dfs_prediction/track3/train_multiphase_fusion.py \
    --radiomics_features data/new/features_all_phases.csv \
    --cnn_features data/new/cnn_features_all_phases.csv \
    --fusion_method hierarchical \
    --epochs 150 \
    --batch_size 16 \
    --exp_name FUSION_5_multiphase_hierarchical
```

**预期性能**:
- **最佳AUC: 0.84-0.88**（项目峰值）
- Sensitivity: 0.78-0.85
- Specificity: 0.80-0.88
- Brier Score: <0.20（良好校准）

---

### 任务4.4: Track 3可视化（1.5小时）

**创建脚本**: `experiments/dfs_prediction/track3/visualize_track3.py`

```bash
PYTHONPATH=src python experiments/dfs_prediction/track3/visualize_track3.py \
    --results_dir experiments/dfs_prediction/track3/results \
    --output_dir experiments/dfs_prediction/track3/visualizations
```

**输出**:
```
track3/visualizations/
├── fusion_methods_comparison.png    # 4种融合方法ROC对比
├── ablation_study_barplot.png       # 消融实验柱状图
├── modality_contribution.png        # 模态贡献饼图/雷达图
└── fusion_weights_heatmap.png       # 学习到的融合权重
```

---

## 📈 阶段5: 综合评估与报告（5-6小时）

### 任务5.1: Track对比评估（2小时）

**修改文件**: `experiments/dfs_prediction/compare_tracks.py`

**增强功能**:
1. 综合ROC/DCA/校准曲线（3个Track最佳模型）
2. 性能汇总表（Markdown + PNG）
3. **DeLong统计检验**（AUC显著性）
4. 指标箱线图（跨Track对比）

**DeLong Test代码**:
```python
from scipy.stats import norm

def delong_test(y_true, y_pred1, y_pred2):
    """DeLong检验比较两个AUC"""
    auc1 = roc_auc_score(y_true, y_pred1)
    auc2 = roc_auc_score(y_true, y_pred2)

    n = len(y_true)
    var1 = auc1 * (1 - auc1) / n
    var2 = auc2 * (1 - auc2) / n

    z = (auc1 - auc2) / np.sqrt(var1 + var2)
    p_value = 2 * (1 - norm.cdf(abs(z)))

    return {'auc1': auc1, 'auc2': auc2, 'z': z, 'p_value': p_value}
```

**执行命令**:
```bash
PYTHONPATH=src python experiments/dfs_prediction/compare_tracks.py \
    --track1_best experiments/dfs_prediction/track1/results/TUNE_5_multiphase_concat \
    --track2_best experiments/dfs_prediction/track2/results/CNN_6_ResNet3D_pretrained \
    --track3_best experiments/dfs_prediction/track3/results/FUSION_5_multiphase_hierarchical \
    --output_dir experiments/dfs_prediction/final_results
```

**输出**:
```
final_results/
├── combined_roc_curves.png
├── combined_dca.png
├── combined_calibration.png
├── performance_comparison_table.png
├── performance_comparison_table.md
├── metric_boxplots.png
└── statistical_tests.csv
```

**性能汇总表示例**:
```markdown
| Track | Method | AUC | ACC | Sens | Spec | F1 | Brier |
|-------|--------|-----|-----|------|------|-----|-------|
| Track 1 | Radiomics+XGBoost | 0.769±0.071 | 0.723±0.059 | 0.701±0.079 | 0.735±0.075 | 0.716±0.065 | 0.228 |
| Track 2 | ResNet3D | 0.814±0.063 | 0.768±0.052 | 0.752±0.068 | 0.778±0.063 | 0.763±0.057 | 0.209 |
| Track 3 | Multiphase Fusion | **0.858±0.055** | **0.812±0.047** | **0.798±0.061** | **0.821±0.058** | **0.808±0.052** | **0.192** |

DeLong Test:
- Track 3 vs Track 2: z=2.84, **p=0.0045** (significant)
- Track 3 vs Track 1: z=4.12, **p<0.001** (highly significant)
```

---

### 任务5.2: 特征相关性分析（1小时）

**创建脚本**: `scripts/analyze_dfs_correlation.py`

**功能**:
- 识别与DFS显著相关的影像组学特征（p<0.05）
- 绘制箱线图展示DCB vs non-DCB差异
- 绘制相关系数热图

```bash
python scripts/analyze_dfs_correlation.py \
    --features data/new/features_VP.csv \
    --output_dir experiments/dfs_prediction/feature_analysis
```

**输出**:
```
feature_analysis/
├── top_correlated_features.csv         # Top 50特征
├── feature_correlation_heatmap.png     # 相关系数热图
├── feature_boxplots.png                # DCB vs non-DCB箱线图
└── significant_features.csv            # p<0.05的显著特征
```

**示例发现**:
```
Top 5 DFS-Associated Features (p<0.01):
1. VP_original_shape_Sphericity: r=-0.342, p=0.0023
2. VP_wavelet-LHL_glcm_ClusterTendency: r=0.318, p=0.0041
3. VP_original_firstorder_Skewness: r=-0.298, p=0.0067
4. VP_log-sigma-2_glrlm_ShortRunEmphasis: r=0.276, p=0.0095
5. VP_wavelet-HHH_gldm_DependenceEntropy: r=0.264, p=0.0128
```

---

### 任务5.3: 综合报告生成（2-3小时）

**创建脚本**: `scripts/generate_final_report.py`

**报告结构**:
```markdown
# 结直肠癌DFS预测 - 综合实验报告

## 1. 项目概述
- 数据集：361例患者，4期CT影像
- 目标：DFS二分类（≥24月 vs <24月）

## 2. Track 1: 影像组学+传统ML
- 最佳模型：TUNE_5 (Multiphase XGBoost)
- AUC: 0.769±0.071
- 关键发现：识别出42个DFS显著相关特征

## 3. Track 2: 深度学习CNN
- 最佳模型：CNN_6 (ResNet3D Pretrained)
- AUC: 0.814±0.063
- 关键发现：3D CNN优于2.5D (+4.2% AUC)

## 4. Track 3: 多模态融合
- 最佳模型：FUSION_5 (Multiphase Hierarchical)
- AUC: 0.858±0.055
- 关键发现：Radiomics+CNN协同效应+10.1% AUC

## 5. Track对比分析
[插入性能对比表]
[插入ROC/DCA/校准曲线]

## 6. 临床意义
- DCA分析：Track 3在阈值0.2-0.5范围内净收益最高
- 推荐决策阈值：0.35（最大净收益点）

## 7. 结论与建议
- 多模态融合显著优于单模态
- 推荐使用Track 3融合模型进行临床DFS预测
```

**执行命令**:
```bash
python scripts/generate_final_report.py \
    --track1_dir experiments/dfs_prediction/track1 \
    --track2_dir experiments/dfs_prediction/track2 \
    --track3_dir experiments/dfs_prediction/track3 \
    --final_results_dir experiments/dfs_prediction/final_results \
    --output experiments/dfs_prediction/DFS_Prediction_Final_Report.md
```

---

## 📋 文件修改与新建清单

### 需要修改的现有文件（4个）

1. **`experiments/dfs_prediction/track1/train_radiomics.py`**
   - 位置：main()函数末尾
   - 添加：DCA、校准曲线、特征相关性热图（~30行代码）

2. **`experiments/dfs_prediction/track2/train_cnn.py`**
   - 位置：DFSImageDataset类
   - 添加：数据增强函数（~50行代码）

3. **`experiments/dfs_prediction/track3/train_fusion.py`**
   - 位置：训练循环
   - 优化：Early stopping逻辑，添加DCA/校准曲线（~20行）

4. **`experiments/dfs_prediction/compare_tracks.py`**
   - 大幅增强：DeLong检验、综合可视化、性能表生成（~200行）

### 需要新建的文件（12个）

#### 阶段1 - 数据准备
1. `scripts/verify_data_completeness.py` (~100行)
2. `scripts/create_data_splits.py` (~80行)

#### 阶段2 - Track 1
3. `experiments/dfs_prediction/track1/train_multiphase_radiomics.py` (~400行)
4. `experiments/dfs_prediction/track1/visualize_track1.py` (~300行)

#### 阶段3 - Track 2
5. `experiments/dfs_prediction/track2/train_resnet3d.py` (~500行)
6. `experiments/dfs_prediction/track2/train_multiphase_cnn.py` (~600行)
7. `experiments/dfs_prediction/track2/extract_cnn_features.py` (~200行)
8. `experiments/dfs_prediction/track2/visualize_track2.py` (~250行)

#### 阶段4 - Track 3
9. `experiments/dfs_prediction/track3/train_multiphase_fusion.py` (~500行)
10. `experiments/dfs_prediction/track3/visualize_track3.py` (~250行)

#### 阶段5 - 综合评估
11. `scripts/analyze_dfs_correlation.py` (~300行)
12. `scripts/generate_final_report.py` (~400行)

---

## ⚠️ 风险与应对策略

### 风险1: 小样本过拟合
**表现**: Train AUC > Val AUC + 0.10

**应对**:
- 增强正则化（dropout 0.5, L2 weight_decay 1e-4）
- 数据增强（旋转±15°、翻转、强度扰动）
- Early stopping（patience=20）
- 降低模型复杂度（减少层数/通道数）

**监控**:
```python
if train_auc - val_auc > 0.10:
    warnings.warn("Potential overfitting!")
```

---

### 风险2: 类别不平衡
**表现**: Sensitivity << Specificity

**应对**:
- Track 1: SMOTE + class_weight='balanced'
- Track 2/3: Weighted CrossEntropyLoss
- 评估时同时报告Sensitivity和Specificity

---

### 风险3: 计算资源不足
**表现**: GPU显存不足，训练时间过长

**应对**:
- 减小batch_size: 8→4→2
- 梯度累积：`accumulate_grad_batches=4`
- Mixed Precision训练（节省50%显存）
- 优先Track 1（CPU），再Track 2/3

```python
# Mixed Precision示例
scaler = torch.cuda.amp.GradScaler()
with torch.cuda.amp.autocast():
    output = model(x)
    loss = criterion(output, y)
scaler.scale(loss).backward()
```

---

### 风险4: 特征提取时间过长
**应对**:
- 最大并行度（`--n_jobs 16`）
- VP期先提取，启动Track 1
- 4期提取后台运行（nohup）

```bash
nohup python ... > feature_extraction.log 2>&1 &
tail -f feature_extraction.log
```

---

### 风险5: 模型泛化能力不足
**应对**:
- 嵌套CV（外层评估，内层调参）
- 独立测试集（15%，仅最后使用一次）
- 校准评估（ECE < 0.15）
- DCA分析（净收益 > 0）

**验证标准**:
```python
assert cv_auc_std < 0.10, "Unstable"
assert ece < 0.15, "Poor calibration"
assert net_benefit > 0, "No clinical utility"
```

---

## ✅ 成功验证标准

### 数据质量
- [ ] 361个患者全部可访问
- [ ] VP期完整率 > 95%
- [ ] 4期完整率 > 90%

### Track 1
- [ ] XGBoost基线 AUC > 0.65
- [ ] 多期相融合 > 单期
- [ ] 识别显著特征（p<0.05）
- [ ] 生成ROC/DCA/校准曲线/特征相关性图

### Track 2
- [ ] 2.5D CNN AUC > 0.70
- [ ] 3D CNN > 2.5D CNN
- [ ] ResNet3D > 简单CNN
- [ ] CNN特征成功提取

### Track 3
- [ ] 融合模型 > 单模态
- [ ] 消融实验显示协同效应
- [ ] 最终AUC > 0.78

### 综合评估
- [ ] Track对比ROC/DCA/校准曲线
- [ ] 性能汇总表完整
- [ ] DeLong统计检验
- [ ] 最终报告（MD）

---

## 📦 最终交付物

### 数据文件（4个）
- `features_VP.csv` (358×1153)
- `features_all_phases.csv` (349×4543)
- `cnn_features_VP.csv` (358×513)
- `data_splits.json`

### 代码文件（16个）
- 4个修改的脚本
- 12个新建脚本

### 模型文件（~83个）
- Track 1: 6个实验 × 3个模型 = 18个.joblib
- Track 2: 8个实验 × 5折 = 40个.pt
- Track 3: 5个实验 × 5折 = 25个.pt

### 可视化图表（50+张）
- ROC/DCA/校准曲线
- 特征相关性图
- 混淆矩阵
- 消融实验图
- 性能对比表

### 文档报告（4个）
- Track 1/2/3可视化报告（MD）
- 综合实验报告（MD）

---

## 🚀 快速开始

### 第1步：数据验证（10分钟）
```bash
python scripts/verify_data_completeness.py \
    --data_dir data/new \
    --metadata data/new/CRC_ldey_Revision.xlsx
```

### 第2步：VP特征提取（3-4小时）
```bash
PYTHONPATH=src python src/radilearn/features/extract_dfs_features.py \
    --data_dir data/new \
    --metadata data/new/CRC_ldey_Revision.xlsx \
    --output data/new/features_VP.csv \
    --phases VP \
    --n_jobs 8
```

### 第3步：Track 1基线（30分钟）
```bash
PYTHONPATH=src python experiments/dfs_prediction/track1/train_radiomics.py \
    --features data/new/features_VP.csv \
    --exp_name TUNE_1_baseline_VP \
    --feature_selection variance \
    --n_features 100
```

### 第4步：后续按计划执行
参考各阶段详细命令

---

## 📞 关键文件路径

### 核心训练脚本
- Track 1: `experiments/dfs_prediction/track1/train_radiomics.py`
- Track 2: `experiments/dfs_prediction/track2/train_cnn.py`
- Track 3: `experiments/dfs_prediction/track3/train_fusion.py`

### 评估模块
- DCA: `src/radilearn/evaluation/dca.py`
- 校准: `src/radilearn/evaluation/calibration.py`

### 模型架构
- CNN: `src/radilearn/models/cnn.py`
- 融合: `src/radilearn/models/fusion.py`

### 特征提取
- Radiomics: `src/radilearn/features/extract_dfs_features.py`

---

**计划编制时间**: 2025-12-02
**预计完成时间**: 3-4天密集工作 或 1-2周常规节奏
**预期最佳AUC**: 0.84-0.88 (Track 3多模态融合)
