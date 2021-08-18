#!/bin/bash

KEYWORD=("かもさん" "内田彩")
LINE_TOKEN=""
WORK_DIR="./"

function onsen_download(){
	target_title=$1
	echo Download「"${target_title}"」
	
	### 最新話パラメータ取得
	contents=`cat ./index.html | jq -r --arg a "${target_title}" '.[] | select(.title == $a) | .contents[]'`
	if [ "${contents}" = "" ] ; then
		echo "No contents."
		return 0
	fi
	title=`cat ./index.html | jq -r --arg a "${target_title}" '.[] | select(.title == $a) | .contents[0].title'`
	poster_image_url=`cat ./index.html | jq -r --arg a "${target_title}" '.[] | select(.title == $a) | .contents[0].poster_image_url'`
	streaming_url=`cat ./index.html | jq -r --arg a "${target_title}" '.[] | select(.title == $a) | .contents[0].streaming_url'`
	guests=`cat ./index.html | jq -r --arg a "${target_title}" '.[] | select(.title == $a) | .contents[0].guests[]'`
	performers=`cat ./index.html | jq -r --arg a "${target_title}" '.[] | select(.title == $a) | .performers[].name'`
	delivery_date=`date "+%Y"`
	delivery_date+="年"
	delivery_date+=`cat ./index.html | jq -r --arg a "${target_title}" '.[] | select(.title == $a) | .contents[0].delivery_date' | sed -e 's/\//月/g'`
	delivery_date+="日"
	track_no=`echo ${title} | sed -e 's/[^0-9]//g'`
	if [ "${guests}" != "" ] ; then
		guest_title=" ゲスト：${guests}"
		guests="${guests}"
	fi
	filename="${target_title} ${title} ${delivery_date}放送${guest_title}.m4a"
	
	### ダウンロード済確認
	downloded=`grep -s "${filename}" ./downloaded.txt`
	if [ "${downloded}" != "" ] ; then
		echo "Already downloaded."
		return 0
	fi
	
	### カバーアート取得
	wget -O "${target_title} ${title} ${delivery_date}放送${guest_title}.jpg" ${poster_image_url}
	
	### ストリーム取得
	ffmpeg -i ${streaming_url} ${codec_option} -acodec copy -bsf:a aac_adtstoasc "${filename}"
	mv ./"${filename}" ./"${filename}.org"
	ffmpeg -i "${filename}.org" -i "${target_title} ${title} ${delivery_date}放送${guest_title}.jpg" -map 0:a -map 1:v -disposition:1 attached_pic -metadata "title=${target_title} ${title}" -metadata "artist=${performers}" -metadata "comment=ゲスト：${guests}" -metadata "album=${target_title}" -metadata "track=${track_no}" -metadata "date=${delivery_date}" -c copy "${filename}"
	rm ./*.org ./*.jpg
	echo "${filename}" >> ./downloaded.txt
	
	### LINE通知
	if [ "${LINE_TOKEN}" != "" ] ; then
		curl -X POST -H "Authorization: Bearer ${LINE_TOKEN}" -F "message=録音完了:${filename//;/；}" https://notify-api.line.me/api/notify
	fi
}

function onsen_search(){
	TARGET=$1

	### ワード検索(タイトル)
	target_title=`cat ./index.html | jq -r '.[].title' | grep ${TARGET}`
	if [ "${target_title}" = "" ] ; then
		echo "No title : ${TARGET}"
	else
		onsen_download "${target_title}"
	fi

	### ワード検索(出演者)
	performers_title=`cat ./index.html | jq -r --arg a ${TARGET} '.[] | select(.performers[].name == $a) | .title'`
	if [ -n "${performers_title}" ] ; then
		echo "${performers_title[@]}" | while IFS= read line
		do
			onsen_download "${line}"
		done
	else
		echo "No title (performers) : ${TARGET}"
	fi

	### ワード検索(ゲスト)
	guests_title=`cat ./index.html | jq -r --arg a ${TARGET} '.[] | select(.contents[0].guests[]? == $a) | .title'`
	if [ -n "${guests_title}" ] ; then
		echo "${guests_title[@]}" | while IFS= read line
		do
			onsen_download "${line}"
		done
	else
		echo "no title (guests) : ${TARGET}"
	fi
}

### jsonデータ取得
cd ${WORK_DIR}
rm -f ./index.html ./title_list.txt
wget https://www.onsen.ag/web_api/programs/
cat ./index.html | jq -r '.' > ./index.json
cat ./index.html | jq -r '.[].title' > ./title_list.txt

### ストリーム取得
for item in ${KEYWORD[@]}; do
	echo ${KEYWORD[@]} : ${item}
	onsen_search "${item}"
done
