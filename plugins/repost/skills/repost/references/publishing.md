# Publishing reference

The publish stage is driven with [`bsk`](https://github.com/anthropics/browser-skill)
(BrowserSkill CLI, CDP-based, no screenshots needed) against Chrome logged into each
platform. Core loop: `bsk session start --quiet` → `bsk navigate <URL>` →
`bsk snapshot` (aria tree, elements are `@eN`) → `bsk click/fill/upload @eN`.
`bsk upload --ref @eN --file <path>` hands a local file straight to Chrome.

General rules:

- **`bsk upload` caps at 512MB per file, and staging is cumulative per session.** A
  failed upload still consumes staging. Start a **fresh session per large upload** and
  get each upload right the first time.
- **Rich-text fields fail with `fill`.** The description editor is a contenteditable;
  set it with `bsk evaluate` running `document.execCommand("insertText", false, text)`.
  Base64-encode the text and decode it inside the `evaluate` to avoid shell mangling.
- **Reposts = 内容为转载 + a source-credit line** citing the original channel. Never
  declare 自制/原创 for someone else's video — that gets flagged as 搬运.
- Only a **login QR** is truly un-automatable — hand it to the user to scan.

---

## 视频号 (channels.weixin.qq.com/platform)

Publish page: `/platform/post/create`. The whole form lives inside a **`WUJIE-APP`
micro-frontend shadow root**, so `document.querySelector(...)` from the top document
returns nothing — reach fields via `document.querySelector("wujie-app").shadowRoot`.
`bsk snapshot` refs (`@eN`) pierce the shadow root, so prefer them for clicks/uploads.

Flow:

1. **Upload** the portrait render to the dropzone button (its accessible name starts
   "上传时长8小时内…"). `bsk upload` returning "ok" only means the file is in the input —
   WeChat still multipart-PUTs it to `finderassistance*.video.qq.com` (minutes). Wait
   for completion before 发表, or it errors "请上传视频". Completion signals:
   `bsk network | grep uploadpartdfs` winding down, the `video` element `readyState`
   reaching 4, and the cover **编辑** button appearing.
2. **Large-file gotcha — foreground window.** A several-hundred-MB upload only *starts
   decoding/uploading* when the automation Chrome window is the foreground app
   (`document.hidden === false`). Backgrounded → `readyState` stays 0 and nothing
   uploads. Retry fresh sessions until one opens with `document.hidden === false`.
   (Small clips like an 8MB Short upload fine even in a hidden tab.)
3. **视频描述** — the `.input-editor` contenteditable; select-all then
   `execCommand("insertText", …)`.
4. **短标题** — ≤ 16 chars (over-length shows a red warning). Allowed punctuation is
   limited: 书名号/引号/冒号/加号/问号/% and period — **no comma**.
5. **视频标注 → Content is reposted (内容为转载)** — opens an "添加转载来源" box; fill the
   source (original channel + URL) and click 完成. Leave **声明原创 unchecked**.
6. **Cover** — click 编辑 on 封面预览 → 上传封面 → upload the designed cover → 确认.
7. **发表** — on success the page redirects to `/platform/post/list`; read the
   published time there.

First-ever publish on an account pops a one-time real-name-verification mask that
needs the admin's WeChat QR scan — hand it over.

Editing cover/description **after** publish is one-time, irreversible, and leaves a
public "修改记录" on the video — confirm with the user first. Wait until Tencent
finishes processing (thumbnail is no longer the black first frame) before the
"修改描述和封面" entry works.

## 公众号 (mp.weixin.qq.com)

新的创作 → 视频 → title (≤64 chars, locked after save) → accept service rules → upload
→ cover → **保存** (enters the material library; status → 已通过 after transcode +
review) → the 发表 icon on the library row → 视频介绍 (≤300 chars) → **发表** →
broadcast-notify confirm → final step needs the **admin's WeChat QR scan** — hand it
to the user. Close the intro overlays on the home page first.

## Bilibili (member.bilibili.com)

Landscape platform — render with `--layout bili`. Upload page:
`/platform/upload/video/frame`. Verified flow:

1. **Upload** — the file input is hidden (no geometry). `bsk evaluate` to find the
   visible DIV whose text is exactly "上传视频", give it an id, then
   `bsk upload --mode input --selector "#thatId"`. Retry on a fresh session if it
   errors on the 512MB staging cap.
2. **标题** (`placeholder="请输入稿件标题"`) — pre-filled with the filename; clear it via
   the native value setter first, then write (≤80 chars).
3. **简介** — contenteditable; `execCommand("insertText")` (≤2000 chars).
4. **标签** (`placeholder="按回车键Enter创建标签"`) — synthetic Enter doesn't work;
   `bsk fill` one word then `bsk press Enter`, repeat (5–8 tags).
5. **分区** — usually defaults to 人工智能 / 科技·计算机技术; confirm.
6. **创作声明 (required)** — pick **内容为转载**, then fill 转载来源 (original channel +
   credit). Never 内容为自制 for a repost.
7. **封面** — 添加封面 → 封面制作. Bilibili wants a 4:3 main cover (feed card) + a 16:9;
   upload the `make_cover.py --landscape` image to the 4:3 slot, leave 16:9 as a system
   frame, 完成.
8. **立即投稿** — ⚠️ the biggest gotcha: a `bsk` ref-click / synthetic click reports
   "ok" but does NOT trigger submission. Call the button's **native `element.click()`**
   via `bsk evaluate` (find the element whose text is "立即投稿"). Success shows
   "稿件投递成功".

Needs the user logged into Bilibili in Chrome; login/QR is theirs.
