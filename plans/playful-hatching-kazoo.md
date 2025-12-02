# RadiLearn DFS预测项目实施计划

## 项目概述

**目标**: 基于多时相CT影像和临床特征，预测结直肠癌患者的无病生存期(DFS)

**数据集**:
- 361例患者，349例完整4期影像 (AP/VP/DP/NP)
- 18个临床特征 (人口统计、病理、实验室指标)
- 标签: DFS≥24月(持久获益, n=247, 68%) vs DFS<24月(非持久获益, n=114, 32%)

**硬件环境**:
- Apple M4 Pro (14核)
- 48GB 统一内存
- PyTorch MPS加速可用

---

## 技术路线总览

```
                    ┌─────────────────────────────────────┐
                    │           新数据集 (361例)           │
                    │  4期CT影像 + 18临床特征 + DFS标签    │
                    └─────────────────┬───────────────────┘
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
        ▼                             ▼                             ▼
   ┌─────────┐                  ┌─────────┐                  ┌─────────┐
   │ Track 1 │                  │ Track 2 │                  │ Track 3 │
   │影像组学 │                  │深度学习 │                  │多模态  │
   │+传统ML  │                  │  CNN   │                  │  融合  │
   └────┬────┘                  └────┬────┘                  └────┬────┘
        │                             │                             │
        ▼                             ▼                             ▼
  PyRadiomics特征            ResNet50/DenseNet121          影像组学+CNN
  + 临床特征                 + 临床特征融合                + 临床特征
  + XGBoost/RF               2.5D vs 3D对比               中间融合架构
        │                             │                             │
        └─────────────────────────────┼─────────────────────────────┘
                                      │
                                      ▼
                          ┌─────────────────────┐
                          │   模型对比与评估    │
                          │ ROC/AUC/DCA/校准曲线│
                          └─────────────────────┘
```

---

## Phase 0: 数据准备与预处理

### 0.1 数据加载器开发

**文件**: `src/radilearn/data/dfs_dataset.py` (新建)

```python
class DFSDataset:
    """DFS预测数据集加载器"""

    def __init__(self, data_dir, metadata_path, phases=['VP'],
                 clinical_cols=None, transform=None):
        self.phases = phases
        self.clinical_cols = clinical_cols or self._default_clinical_cols()

    def _default_clinical_cols(self):
        return [
            '性别', '年龄', '辅助化疗', '肿瘤位置', 'cT分期', 'cN分期',
            '肿瘤最大径', '组织学分级', '微卫星不稳定性', 'Ki67',
            '周围浸润', '间质评分', 'TSR', 'FAP', 'NLR', 'PLR', 'LMR',
            'CA125', 'CEA', 'CA199', 'AFP'
        ]

    def __getitem__(self, idx):
        # 返回: images_dict, clinical_features, label
        pass
```

### 0.2 元数据处理

**Excel结构解析**:
- 跳过前2行表头
- 病人号列需要补全前导零 (7848721 → 0007848721)
- DFS列转换为二分类: `label = 0 if DFS >= 24 else 1`

### 0.3 数据质量检查

1. 验证影像-元数据匹配率
2. 检查缺失值分布
3. 分析各期影像完整性
4. 临床特征分布统计

---

## Phase 1: Track 1 - 影像组学 + 传统ML

### 1.1 特征提取

**四期影像组学特征提取**:

```bash
# 对每个时相分别提取特征
for phase in AP VP DP NP; do
    python src/radilearn/features/extract_features.py \
        --image_dir data/new \
        --phase $phase \
        --output data/new/features_${phase}.csv
done
```

**特征维度**: ~1595 × 4期 = 6380维影像组学特征

### 1.2 临床特征整合

**临床特征预处理**:
- 数值型: StandardScaler标准化
- 类别型: One-Hot编码
- 缺失值: 均值/众数填充

**融合策略**:
```python
X_combined = np.hstack([
    radiomics_features,  # 6380维 (选择性融合后约400维)
    clinical_features    # 18维
])
```

### 1.3 特征选择

**阶段1: 各期独立选择**
```python
# 每期选择top-100高方差特征 (无偏方法)
from sklearn.feature_selection import VarianceThreshold
selector = VarianceThreshold()
# 选择方差排名前100的特征
```

**阶段2: 跨期相关性分析**
- 计算各期特征间Pearson相关系数
- 移除高度相关特征 (r > 0.9)
- 保留最具判别力的时相特征

### 1.4 模型训练

**基线模型** (复用现有代码):
```python
models = {
    'XGBoost': XGBClassifier(
        n_estimators=200, max_depth=5, learning_rate=0.08,
        scale_pos_weight=247/114,  # 类别权重
        use_label_encoder=False
    ),
    'RandomForest': RandomForestClassifier(
        n_estimators=300, max_depth=6,
        class_weight='balanced'
    ),
    'LightGBM': LGBMClassifier(
        n_estimators=200, num_leaves=31,
        class_weight='balanced'
    )
}
```

**交叉验证**: 5-fold StratifiedKFold + SMOTE过采样

### 1.5 输出

- `experiments/track1_dfs/` 目录
- 各模型性能对比
- 特征重要性分析
- ROC曲线

---

## Phase 2: Track 2 - 深度学习CNN

### 2.1 架构选择

基于M4 Pro + 48GB配置，推荐两种架构对比:

**架构A: 2.5D ResNet50 (推荐)**
```python
class MultiPhase25DCNN(nn.Module):
    """2.5D多时相CNN"""
    def __init__(self, num_phases=4, num_clinical=18):
        # 每个时相: 取5个相邻切片作为5通道输入
        self.phase_encoders = nn.ModuleList([
            ResNet50(pretrained='radimagenet', in_channels=5)
            for _ in range(num_phases)
        ])
        self.clinical_encoder = nn.Sequential(
            nn.Linear(num_clinical, 64),
            nn.ReLU(),
            nn.Dropout(0.5)
        )
        self.fusion = nn.Sequential(
            nn.Linear(2048 * num_phases + 64, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, 1)
        )
```

**架构B: 3D ResNet18 (对比)**
```python
class MultiPhase3DCNN(nn.Module):
    """3D多时相CNN"""
    def __init__(self, num_phases=4, num_clinical=18):
        # 每个时相: 完整3D体积输入
        self.phase_encoders = nn.ModuleList([
            ResNet3D_18(pretrained='med3d')
            for _ in range(num_phases)
        ])
        # 融合层同上
```

### 2.2 预训练权重

**RadImageNet权重** (首选):
```python
# 下载地址: https://github.com/BMEII-AI/RadImageNet
# 使用医学影像预训练，比ImageNet更适合
```

**Med3D权重** (3D CNN):
```python
# 下载地址: https://github.com/Tencent/MedicalNet
# 23个医学影像数据集预训练
```

### 2.3 数据增强

```python
train_transforms = A.Compose([
    A.Rotate(limit=15, p=0.5),
    A.ShiftScaleRotate(shift_limit=0.1, scale_limit=0.1, p=0.5),
    A.GaussNoise(var_limit=(10, 50), p=0.3),
    A.RandomBrightnessContrast(brightness_limit=0.1, p=0.3),
])
```

### 2.4 训练配置

```python
config = {
    'batch_size': 8,  # M4 Pro可支持
    'learning_rate': 1e-4,
    'epochs': 100,
    'early_stopping_patience': 15,
    'optimizer': 'AdamW',
    'scheduler': 'CosineAnnealingLR',
    'device': 'mps',  # Apple Silicon

    # 类别不平衡处理
    'class_weights': torch.tensor([1.0, 2.17]),  # 247/114
    'use_smote': True,
}
```

### 2.5 注意力机制

**CBAM模块** (推荐添加):
```python
class CBAM(nn.Module):
    """Channel and Spatial Attention Module"""
    def __init__(self, channels, reduction=16):
        self.channel_attention = ChannelAttention(channels, reduction)
        self.spatial_attention = SpatialAttention()
```

### 2.6 输出

- `experiments/track2_dfs/` 目录
- 2.5D vs 3D性能对比
- 学习曲线
- Grad-CAM可视化

---

## Phase 3: Track 3 - 多模态融合

### 3.1 融合架构

**中间融合策略** (Intermediate Fusion):

```
影像组学分支 ─────┐
(400维特征)      │
                 ├──► 融合层 ──► 预测
CNN分支 ─────────┤    (512维)
(2048×4维)       │
                 │
临床特征分支 ────┘
(18维)
```

### 3.2 实现

```python
class MultiModalFusion(nn.Module):
    """多模态融合模型"""

    def __init__(self, radiomics_dim=400, cnn_dim=2048*4, clinical_dim=18):
        # 影像组学编码器
        self.radiomics_encoder = nn.Sequential(
            nn.Linear(radiomics_dim, 128),
            nn.ReLU(),
            nn.Dropout(0.5)
        )

        # CNN编码器 (使用预训练的2.5D CNN)
        self.cnn_encoder = Pretrained25DCNN()

        # 临床特征编码器
        self.clinical_encoder = nn.Sequential(
            nn.Linear(clinical_dim, 64),
            nn.ReLU(),
            nn.Dropout(0.4)
        )

        # 融合层
        self.fusion = nn.Sequential(
            nn.Linear(128 + 512 + 64, 256),  # 704 → 256
            nn.BatchNorm1d(256),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(256, 128),
            nn.ReLU(),
            nn.Dropout(0.4),
            nn.Linear(128, 1),
            nn.Sigmoid()
        )
```

### 3.3 消融实验

| 实验 | 影像组学 | CNN | 临床 | 目的 |
|------|:-------:|:---:|:----:|------|
| A | ✓ | ✗ | ✗ | 影像组学基线 |
| B | ✗ | ✓ | ✗ | CNN基线 |
| C | ✗ | ✗ | ✓ | 临床特征基线 |
| D | ✓ | ✗ | ✓ | 影像组学+临床 |
| E | ✗ | ✓ | ✓ | CNN+临床 |
| F | ✓ | ✓ | ✗ | 影像组学+CNN |
| **G** | **✓** | **✓** | **✓** | **完整融合** |

---

## Phase 4: 评估与可视化

### 4.1 性能指标

```python
metrics = {
    'AUC': roc_auc_score,
    'Accuracy': accuracy_score,
    'Sensitivity': recall_score,
    'Specificity': lambda y, p: recall_score(y, p, pos_label=0),
    'F1': f1_score,
    'Brier Score': brier_score_loss,
}
```

### 4.2 ROC曲线

```python
def plot_roc_comparison(results_dict, save_path):
    """绘制多模型ROC对比图"""
    plt.figure(figsize=(10, 8))
    for name, (y_true, y_pred) in results_dict.items():
        fpr, tpr, _ = roc_curve(y_true, y_pred)
        auc = roc_auc_score(y_true, y_pred)
        plt.plot(fpr, tpr, label=f'{name} (AUC={auc:.3f})')
    plt.plot([0,1], [0,1], 'k--')
    plt.xlabel('1 - Specificity')
    plt.ylabel('Sensitivity')
    plt.legend()
    plt.savefig(save_path)
```

### 4.3 决策曲线分析 (DCA)

```python
def decision_curve_analysis(y_true, y_pred_proba, save_path):
    """决策曲线分析"""
    thresholds = np.arange(0, 1, 0.01)
    net_benefits = []

    for thresh in thresholds:
        y_pred = (y_pred_proba >= thresh).astype(int)
        tp = np.sum((y_pred == 1) & (y_true == 1))
        fp = np.sum((y_pred == 1) & (y_true == 0))
        n = len(y_true)

        net_benefit = (tp/n) - (fp/n) * (thresh / (1 - thresh))
        net_benefits.append(net_benefit)

    # 绘制DCA曲线
    plt.plot(thresholds, net_benefits, label='Model')
    plt.plot(thresholds, [0]*len(thresholds), label='Treat None')
    # ...
```

### 4.4 校准曲线

```python
def calibration_plot(y_true, y_pred_proba, n_bins=10, save_path=None):
    """校准曲线分析"""
    from sklearn.calibration import calibration_curve

    fraction_of_positives, mean_predicted_value = calibration_curve(
        y_true, y_pred_proba, n_bins=n_bins
    )

    plt.plot(mean_predicted_value, fraction_of_positives, 's-', label='Model')
    plt.plot([0, 1], [0, 1], 'k--', label='Perfect calibration')
    plt.xlabel('Mean Predicted Probability')
    plt.ylabel('Fraction of Positives')
    plt.legend()
```

### 4.5 特征重要性与相关性

```python
def plot_feature_correlation(features_df, top_n=30, save_path=None):
    """绘制DFS相关特征热图"""
    correlations = features_df.corrwith(dfs_labels)
    top_features = correlations.abs().nlargest(top_n)

    # 热图可视化
    sns.heatmap(features_df[top_features.index].corr(),
                annot=True, cmap='RdBu_r')
```

---

## 文件结构规划

```
RadiLearn/
├── data/
│   └── new/                      # 新数据集
│       ├── 0000205641/          # 患者目录
│       │   ├── *_AP_img.nii.gz
│       │   ├── *_AP_segCRC.nii.gz
│       │   ├── *_VP_img.nii.gz
│       │   └── ...
│       ├── CRC_ldey_Revision.xlsx
│       ├── dataset.md
│       ├── task.md
│       ├── features_AP.csv       # (新生成)
│       ├── features_VP.csv
│       ├── features_DP.csv
│       ├── features_NP.csv
│       └── features_combined.csv
│
├── src/radilearn/
│   ├── data/
│   │   ├── dataset.py            # 现有
│   │   ├── dfs_dataset.py        # 新增: DFS数据加载器
│   │   └── preprocess.py         # 现有
│   │
│   ├── features/
│   │   ├── extract_features.py   # 现有: 修改支持新数据格式
│   │   └── fusion.py             # 新增: 多时相融合
│   │
│   ├── models/
│   │   ├── cnn_2d.py             # 新增: 2.5D CNN
│   │   ├── cnn_3d.py             # 新增: 3D CNN
│   │   ├── fusion_model.py       # 新增: 多模态融合
│   │   └── attention.py          # 新增: CBAM注意力
│   │
│   ├── training/
│   │   ├── train_ml.py           # 现有: 修改支持DFS
│   │   ├── train_cnn.py          # 现有: 大幅重构
│   │   └── train_fusion.py       # 新增: 融合模型训练
│   │
│   └── evaluation/
│       ├── evaluate.py           # 现有
│       ├── dca.py                # 新增: 决策曲线分析
│       └── calibration.py        # 新增: 校准曲线
│
├── experiments/
│   ├── dfs_prediction/           # 新增实验目录
│   │   ├── README.md             # 实验总览
│   │   ├── track1/               # Track 1实验
│   │   ├── track2/               # Track 2实验
│   │   └── track3/               # Track 3实验
│   └── ...
│
└── notebooks/
    ├── 01_data_exploration.ipynb  # 新增: 数据探索
    ├── 02_feature_analysis.ipynb  # 新增: 特征分析
    └── 03_results_comparison.ipynb # 新增: 结果对比
```

---

## 实施步骤

### Step 1: 数据准备 (1-2天)
- [ ] 开发DFSDataset数据加载器
- [ ] 解析Excel元数据
- [ ] 验证影像-标签匹配
- [ ] 数据质量报告

### Step 2: Track 1 影像组学 (3-4天)
- [ ] 四期特征提取
- [ ] 临床特征预处理
- [ ] 特征选择与融合
- [ ] 基线模型训练
- [ ] 性能评估

### Step 3: Track 2 深度学习 (5-7天)
- [ ] 2.5D CNN实现
- [ ] 3D CNN实现
- [ ] 数据增强
- [ ] 模型训练 (MPS加速)
- [ ] 2.5D vs 3D对比

### Step 4: Track 3 多模态融合 (4-5天)
- [ ] 融合架构实现
- [ ] 消融实验
- [ ] 超参数调优
- [ ] 最终模型选择

### Step 5: 评估与可视化 (2-3天)
- [ ] ROC曲线对比
- [ ] 决策曲线分析
- [ ] 校准曲线
- [ ] 特征重要性图
- [ ] 实验报告撰写

---

## 关键依赖

```bash
# 核心依赖
pip install torch torchvision  # PyTorch (已安装)
pip install monai              # 医学影像深度学习
pip install albumentations     # 数据增强
pip install optuna             # 超参数优化

# 影像组学
pip install pyradiomics        # 已安装
pip install simpleitk nibabel  # 已安装

# 可视化
pip install matplotlib seaborn # 已安装
pip install plotly             # 交互式图表

# 评估
pip install lifelines          # 生存分析
pip install dcurves            # 决策曲线分析
```

---

## 预期结果

基于类似研究和数据规模，预期性能范围:

| Track | 方法 | 预期AUC | 备注 |
|-------|------|---------|------|
| Track 1 | 影像组学+临床+XGBoost | 0.70-0.78 | 基线 |
| Track 2 | 2.5D CNN+临床 | 0.75-0.82 | 深度学习 |
| Track 2 | 3D CNN+临床 | 0.76-0.84 | 更高但更慢 |
| **Track 3** | **多模态融合** | **0.80-0.88** | **最佳预期** |

---

## 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 类别不平衡严重 | 模型偏向多数类 | SMOTE + 类别权重 |
| 多时相数据缺失 | 样本减少 | 仅使用完整4期患者(349例) |
| 过拟合 | 泛化能力差 | 强正则化 + 早停 + 5折CV |
| 特征维度过高 | 计算负担 | 方差选择 + PCA降维 |
| MPS兼容性 | 某些操作不支持 | 回退CPU或调整实现 |

---

## 下一步行动

确认此计划后，我将按以下顺序执行:

1. **首先**: 创建`DFSDataset`数据加载器并验证数据完整性
2. **然后**: 并行启动Track 1和Track 2的特征提取/模型开发
3. **最后**: 整合Track 3融合模型并进行全面评估
