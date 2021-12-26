#!/bin/bash

KEYWORD=("せず" "山口勝平")
LINE_TOKEN=""
WORK_DIR="./"

function hibiki_download(){
	target_title=$1
	echo Download「"${target_title}"」
	
	### 最新話パラメータ取得
	episode=`cat ./programs | jq -r --arg a "${target_title}" '.[] | select(.name == $a) | .episode'`
	if [ "${episode}" = "" ] ; then
		echo "No episode."
		return 0
	fi
	title=`cat ./programs | jq -r --arg a "${target_title}" '.[] | select(.name == $a) | .episode.name'`
	poster_image_url=`cat ./programs | jq -r --arg a "${target_title}" '.[] | select(.name == $a) | .pc_image_url'`
	video_id=`cat ./programs | jq -r --arg a "${target_title}" '.[] | select(.name == $a) | .episode.video.id'`
	performers=`cat ./programs | jq -r --arg a "${target_title}" '.[] | select(.name == $a) | .cast'`
	delivery_date=`cat ./programs | jq -r --arg a "${target_title}" '.[] | select(.name == $a) | .episode.updated_at' | sed -e "s/\//／/g" | cut -c 1-14`
	track_no=`echo ${title} | sed -e 's/[^0-9]//g'`
	filename="${target_title} ${title} ${delivery_date}放送.m4a"
	
	### ダウンロード済確認
	downloded=`grep -s "${filename}" ./downloaded.txt`
	if [ "${downloded}" != "" ] ; then
		echo "Already downloaded."
		return 0
	fi
	
	### カバーアート取得
	wget -O "${target_title} ${title} ${delivery_date}放送${guest_title}.jpg" ${poster_image_url}
	
	### ストリーム取得
	wget  -O "url.json" --header="X-Requested-With: XMLHttpRequest" https://vcms-api.hibiki-radio.jp/api/v1/videos/play_check?video_id=${video_id}
	streaming_url=`cat ./url.json | jq -r .playlist_url`
	ffmpeg -i ${streaming_url} ${codec_option} -acodec copy -bsf:a aac_adtstoasc "${filename}"
	mv ./"${filename}" ./"${filename}.org"
	ffmpeg -i "${filename}.org" -i "${target_title} ${title} ${delivery_date}放送${guest_title}.jpg" -map 0:a -map 1:v -disposition:1 attached_pic -metadata "title=${target_title} ${title}" -metadata "artist=${performers}" -metadata "album=${target_title}" -metadata "track=${track_no}" -metadata "date=${delivery_date}" -c copy "${filename}"
	rm ./*.org ./*.jpg
	echo "${filename}" >> ./downloaded.txt
	
	### LINE通知
	if [ "${LINE_TOKEN}" != "" ] ; then
		curl -X POST -H "Authorization: Bearer ${LINE_TOKEN}" -F "message=録音完了:${filename//;/；}" https://notify-api.line.me/api/notify
	fi
}

function hibiki_search(){
	TARGET=$1

	### ワード検索(タイトル)
	target_title=`cat ./programs | jq -r '.[].name' | grep ${TARGET}`
	if [ "${target_title}" = "" ] ; then
		echo "no title : ${TARGET}"
	else
		hibiki_download "${target_title}"
	fi
}

### jsonデータ取得
cd ${WORK_DIR}
rm -f ./programs ./title_list.csv
wget --header="X-Requested-With: XMLHttpRequest" https://vcms-api.hibiki-radio.jp/api/v1/programs
cat ./programs | jq -r '.' > ./programs.json
cat ./programs | jq -r '.[].name' > ./title_list.txt

### 番組表取得
i=0
for prog_id in `cat ./programs | jq -r '.[].id'`; do
	cat ./programs | jq -r --argjson a ${i} '.[$a] | [.name, .latest_episode_name?, .updated_at?, .cast? ] | @csv' >> ./title_list.csv
	((i++))
done

### ストリーム取得
for item in ${KEYWORD[@]}; do
	echo ${KEYWORD[@]} : ${item}
	hibiki_search "${item}"
done
