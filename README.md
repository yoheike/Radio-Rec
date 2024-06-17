# Radio-Rec
Internet radio recording automation scripts.

- 音泉(https://www.onsen.ag/) から特定の最新放送をダウンロードするbashスクリプトです (rec-onsen.sh)
- 響ラジオステーション(https://hibiki-radio.jp/) 向けのスクリプトも有ります (rec-hibiki.sh)
- NHKラジオ らじる らじる 向けのスクリプトも作成しました (rec-nhk.sh)
- ffmpeg、jqを使用します

## 仕様

- 番組タイトルからキーワードを検索してダウンロードします
- 出演者・ゲストから、完全一致で検索してダウンロードします (音泉のみ)
- 各番組の最新話を対象としてダウンロードします
- 動画番組の場合も決め打ちでm4aとしてダウンロードします
- LINE Tokenを登録する事で、ダウンロード完了時に通知を行います

## 変数説明

| 変数       | 説明                           |
| ---------- | ------------------------------ |
| KEYWORD    | テキスト配列でダウンロード対象 |
| LINE_TOKEN | 完了通知用LINE Token           |
| WORK_DIR   | 一時ファイル用ディレクトリ     |

