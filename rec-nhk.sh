#!/bin/bash -x

KEYWORD=("ジャズ・ヴォヤージュ"
         "ジャズ・トゥナイト"
         )

# Parameter
LINE_TOKEN="	"
WORK_DIR="./"

function nhk_download(){
	target_title=$1
	echo Download「"${target_title}"」
	
	### 番組情報取得
	series_site_id=`cat ./index.json | jq -r --arg a "${target_title}" '.corners[] | select(.title == $a) | .series_site_id'`
	corner_site_id=`cat ./index.json | jq -r --arg a "${target_title}" '.corners[] | select(.title == $a) | .corner_site_id'`
	
	wget -O ./detail_json "https://www.nhk.or.jp/radio-api/app/v1/web/ondemand/series?site_id=${series_site_id}&corner_site_id=${corner_site_id}"
	cat ./detail_json | jq -r '.' > detail.json

	### 最新話パラメータ取得
	cat ./detail.json | jq -r '.episodes[]' > contents.json

	title=`cat ./contents.json | jq -r '.program_title'`
	title_sub=`cat ./contents.json | jq -r '.program_sub_title'`
	poster_image_url=`cat ./detail.json | jq -r '.thumbnail_url'`
	streaming_url=`cat ./contents.json | jq -r '.stream_url'`
	delivery_date=`cat ./contents.json | jq -r '.onair_date'`
	date_text=`echo ${delivery_date} | sed 'y/!?&:\/\"/！？＆：／”/'`
	filename="${title}_${date_text}.m4a"
	
	### ダウンロード済確認
	downloded=`grep -s "${filename}" ./downloaded.txt`
	if [ "${downloded}" != "" ] ; then
		echo "  Already downloaded. ${downloded}"
		return 0
	fi
	
	### カバーアート取得
	wget -O "${target_title}.jpg" ${poster_image_url}
	
	### ストリーム取得
	ffmpeg  -http_seekable 0 -i "${streaming_url}" -vn -acodec copy ./"${filename}"

	mv ./"${filename}" ./"${filename}.org"
	ffmpeg -i ./"${filename}.org" -i "${target_title}.jpg" -map 0:a -map 1:v -disposition:1 attached_pic -metadata "title=${title} ${title_sub}" -metadata "artist=${target_title}" -metadata "album=${target_title}" -metadata "date=${delivery_date}" -c copy "${filename}"
	rm ./*.org

	echo "${filename}" >> ./downloaded.txt
	
	### LINE通知
	if [ "${LINE_TOKEN}" != "" ] ; then
		curl -X POST -H "Authorization: Bearer ${LINE_TOKEN}" -F "message=録音完了:${filename}" -F "imageFile=@${target_title}.jpg" https://notify-api.line.me/api/notify
	fi
}

function nhk_search(){
	TARGET=$1

	### ワード検索(タイトル)
	target_title=`cat ./index.json | jq -r '.corners[].title' | grep "${TARGET}"`
	if [ "${target_title}" = "" ] ; then
		echo "  no title : ${TARGET}"
	else
		nhk_download "${target_title}"
	fi
}

### Init
mkdir -p ${WORK_DIR}
cd ${WORK_DIR}
rm -f ./*.json
rm -f ./new_arrivals

### 番組表取得
wget https://www.nhk.or.jp/radio-api/app/v1/web/ondemand/corners/new_arrivals
cat ./new_arrivals | jq -r '.' > ./index.json

### 検索
for item in ${KEYWORD[@]}; do
	echo ${KEYWORD[@]} : ${item}
	nhk_search "${item}"
done

