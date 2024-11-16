#!/bin/bash

# تابعی برای نمایش منو
show_menu() {
    echo "*********** MENU ***********"
    echo "1. Bazgasht Be Menu"
    echo "2. Download Ba ffmpeg"
    echo "3. Download Ba yt-dlp"
    echo "4. Estekhrag Format Online"
    echo "5. Khorooj Az Barname"
    echo "****************************"
    echo "Lotfan Shomare Gozine Mored Nazar Ra Vared Konid:"
}

# تابع برای نمایش لینک‌ها به صورت جدول با فرمت زیبا و جداشده
display_table() {

echo "

Using User-Agent: $RANDOM_USER_AGENT
"
    echo -e "Shomare | File Name                | Hajm (MB) | Duration | Resolution | Link"
    echo "-----------------------------------------------------------------------------------------"
    for i in "${!ALL_URLS[@]}"; do
        FILE_URL=${ALL_URLS[$i]}
        FILE_NAME=$(basename "$FILE_URL")

        # دریافت حجم فایل
        FILE_SIZE=$(curl -sI -A "$RANDOM_USER_AGENT" "$FILE_URL" | grep -i Content-Length |  awk '{print $2}' | tr -d '\r')
        if [ -n "$FILE_SIZE" ]; then
            FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
        else
            FILE_SIZE_MB="N/A"
        fi

        # دریافت کیفیت و رزولوشن بدون دانلود کامل فایل
        if command -v ffprobe &> /dev/null; then
            FILE_INFO=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,duration -of default=noprint_wrappers=1 "$FILE_URL" 2>/dev/null)
            DURATION=$(echo "$FILE_INFO" | grep '^duration=' | cut -d '=' -f2 | xargs printf "%.0f" 2>/dev/null)
            RESOLUTION=$(echo "$FILE_INFO" | grep '^width=' | cut -d '=' -f2)
            HEIGHT=$(echo "$FILE_INFO" | grep '^height=' | cut -d '=' -f2)
            RESOLUTION="${RESOLUTION}x${HEIGHT}"

            # فرمت کردن زمان به قالب mm:ss
            if [ -n "$DURATION" ]; then
                DURATION_FORMATTED=$(printf "%02d:%02d" $((DURATION/60)) $((DURATION%60)))
            else
                DURATION_FORMATTED="N/A"
            fi
        else
            RESOLUTION="N/A"
            DURATION_FORMATTED="N/A"
        fi

        # نمایش هر سطر جدول با فرمت زیبا
        printf "%-8s| %-24s| %-10s| %-9s| %-11s| %s\n" "$((i+1))" "$FILE_NAME" "$FILE_SIZE_MB" "$DURATION_FORMATTED" "$RESOLUTION" "$FILE_URL"
    done
    echo "-----------------------------------------------------------------------------------------"
}

# تابع برای اصلاح نام فایل
sanitize_filename() {
    echo "$1" | sed 's/[\/:*?"<>|]/_/g'
}

# متغیرها برای ذخیره URL ها و تنظیمات
ALL_URLS=()
SELECTED_URL=""
FORMAT="ogg"
RESOLUTION="original"
BITRATE="original"
USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Gecko/20100101 Firefox/90.0"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15"
)

while true; do

    # انتخاب یوزر اجنت به صورت تصادفی
    RANDOM_USER_AGENT=${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}

    show_menu
    read -r CHOICE

    case $CHOICE in
        1)
            # بازگشت به منوی اصلی
            echo "Bazgasht be menu asli ...."
            continue
            ;;

        2)
            # پرسش برای لینک جدید
            echo "Agar Mikhahid Link Jadid Ra Vared Konid.  Dar Gheire In Soorat, Enter Ra Feshar Dahid Ta Az Link Ghabli Estefade Konim."
            read -r -p "Link Jadid Ra Vared Konid (Ya Enter Baraye Estefade Az Link Ghabli): " NEW_MEDIA_URL

            if [ -n "$NEW_MEDIA_URL" ]; then
                MEDIA_URL=$NEW_MEDIA_URL
echo "Using User-Agent: $RANDOM_USER_AGENT"
                PAGE_CONTENT=$(curl -s -A "$RANDOM_USER_AGENT" "$MEDIA_URL")

                # استخراج لینک‌ها
                AUDIO_URLS=($(echo "$PAGE_CONTENT" | grep -oP 'https?://[^"]+\.(mp3|m4a|wav|ogg|aac|flac|wma|opus|aiff|alac|m4b|dsd|dff|dsf)'))
                VIDEO_URLS=($(echo "$PAGE_CONTENT" | grep -oP 'https?://[^"]+\.(mp4|mkv|avi|mov|flv|wmv|webm|mpeg|m4v|3gp|ogg|ogv|drc|m4p|f4v|f4p|h263|h264|hevc|vp8|vp9)'))
                VIDEO_STREAM_URLS=($(echo "$PAGE_CONTENT" | grep -oP '<video[^>]*>\s*<source src="\K[^"]+'))
                HLS_URLS=($(echo "$PAGE_CONTENT" | grep -oP 'https?://[^"]+\.m3u8'))

                ALL_URLS=("${AUDIO_URLS[@]}" "${VIDEO_URLS[@]}" "${VIDEO_STREAM_URLS[@]}" "${HLS_URLS[@]}")

                if [ ${#ALL_URLS[@]} -eq 0 ]; then
                    echo "Link Download Peida Nashod."
                    continue
                fi

                echo "Link Jadid Ba Movafaghiat Zakhire Shod."
            fi

            display_table

            echo "Lotfan Shomare File Mored Nazar Baraye Download Ra Vared Konid (Ya 0 Baraye Bazgasht Be Menu):"
            read -r OPTION

            if ! [[ "$OPTION" =~ ^[0-9]+$ ]] || [ "$OPTION" -le 0 ] || [ "$OPTION" -gt "${#ALL_URLS[@]}" ]; then
                echo "Bazgasht be menu."
                continue
            fi

            SELECTED_URL=${ALL_URLS[$((OPTION-1))]}
            echo "File Mored Nazar Shoma: $SELECTED_URL"

            # تشخیص نوع فایل
            if [[ "$SELECTED_URL" == *.mp3 || "$SELECTED_URL" == *.m4a || "$SELECTED_URL" == *.wav || "$SELECTED_URL" == *.oga || "$SELECTED_URL" == *.ogg || "$SELECTED_URL" == *.aac || "$SELECTED_URL" == *.flac || "$SELECTED_URL" == *.wma || "$SELECTED_URL" == *.mka ]]; then
                FILE_TYPE="audio"
            else
                FILE_TYPE="video"
            fi

            while true; do
                echo "Agar Mikhahid Format Ya Resolution Ra Taghir Dahid, Mitavanid Be Sorate Zir Vared Konid (Ba Zadan Enter, Maqdar Pishfarz Set Mishavad):"
                if [[ "$FILE_TYPE" == "audio" ]]; then
                    echo "1. Format: mp3, wav, ... (misal: mp3)"
                    echo "2. Bitrate: 128k, 192k, 320k (misal: 192k)"
                else
                    echo "1. Format: mp4, mkv, ... (misal: mp4)"
                    echo "2. Resolution: 720p, 1080p, ... (misal: 720p)"
                    echo "3. Bitrate: 2000k, 3000k, ... (misal: 2000k)"
                fi
                echo "Agar Nemikhahid Taghir Dahid,Enter Ra Feshar Dahid."

                if [[ "$FILE_TYPE" == "audio" ]]; then
                    read -r -p "Lotfan Format Ra Vared Konid (Ya Enter Baraye Pishfarz): " NEW_FORMAT
                    read -r -p "Lotfan Bitrate Ra Vared Konid (Ya Enter Baraye Pishfarz): " NEW_BITRATE

                    # تنظیم مقادیر جدید اگر کاربر مقداری وارد کند
                    FORMAT=${NEW_FORMAT:-$FORMAT}
                    BITRATE=${NEW_BITRATE:-$BITRATE}
                    
                    [[ "$SELECTED_URL" == *.mp3 ]] && FORMAT="mp3"
                    [[ "$SELECTED_URL" == *.m4a ]] && FORMAT="m4a"
                    [[ "$SELECTED_URL" == *.wav ]] && FORMAT="wav"
                    [[ "$SELECTED_URL" == *.ogg ]] && FORMAT="ogg"
                    [[ "$SELECTED_URL" == *.oga ]] && FORMAT="oga"
                    [[ "$SELECTED_URL" == *.aac ]] && FORMAT="aac"
                    [[ "$SELECTED_URL" == *.flac ]] && FORMAT="flac"
                    [[ "$SELECTED_URL" == *.wma ]] && FORMAT="wma"
                    [[ "$SELECTED_URL" == *.mka ]] && FORMAT="mka"

                else
                    read -r -p "Lotfan Format Ra Vared Konid (Ya Enter Baraye Pishfarz): " NEW_FORMAT
                    read -r -p "Lotfan Resolution Ra Vared Konid (Ya Enter Baraye Pishfarz): " NEW_RESOLUTION
                    read -r -p "Lotfan Bitrate Ra Vared Konid (Ya Enter Baraye Pishfarz): " NEW_BITRATE

                    # تنظیم مقادیر جدید اگر کاربر مقداری وارد کند
                    FORMAT=${NEW_FORMAT:-$FORMAT}
                    RESOLUTION=${NEW_RESOLUTION:-$RESOLUTION}
                    BITRATE=${NEW_BITRATE:-$BITRATE}
                fi

                FFENC_PARAM="-b:a $BITRATE"
                [[ "$BITRATE" == "original" ]] && FFENC_PARAM="-c copy"
                # نمایش مقادیر فعلی
                echo "Maqdari Ke Shoma Vared Kardid:"
                echo "Format: $FORMAT"
                echo "Bitrate: $BITRATE"
                echo "Resolution: $RESOLUTION"
                read -r -p "Agar In Maqdar Dorost Ast, Enter Ra Feshar Dahid. Agar Na, Bazgasht Be Menu  (1). " CONFIRM
                if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
                    break
                fi
            done

            # اصلاح نام فایل
            OUTPUT_FILENAME=$(sanitize_filename "$(basename "$SELECTED_URL" | sed 's/\.[^.]*$//')")_$FORMAT

            # اجرای ffmpeg برای تبدیل فرمت
            echo "Dar Hal Download va Tabdil .... $SELECTED_URL be $OUTPUT_FILENAME.$FORMAT ..."
            CMD="ffmpeg -i $SELECTED_URL $FFENC_PARAM $OUTPUT_FILENAME.$FORMAT"
            printf "\n$CMD\n\n"
            eval $CMD

            echo "Download Va Tabdil Be Ebtmam Resid: $OUTPUT_FILENAME.$FORMAT"
            ;;

        3)
            echo "Download Ba yt-dlp ..."
            read -r -p "Lotfan Link Download Ra Vared Konid: " DOWNLOAD_URL
            echo "Link Download: $DOWNLOAD_URL"

            # استخراج لینک‌های قابل دانلود با yt-dlp
            yt-dlp -F "$DOWNLOAD_URL"

            echo "Lotfan Format/ID Ke Mikhahid Download Konid Ra Vared Konid (mesal:480p,hls-937,439)

**Dar Soraty Ke File Sound Va video Joda Bod Mitavanid Ba Zadan (ID Sound+ID video) File Yekparcheh Dashteh Bashid"
            read -r FORMAT_OPTION

            # دانلود فرمت انتخابی
            yt-dlp -f "$FORMAT_OPTION" "$DOWNLOAD_URL"
            echo "Download File Morede Nazar Be Etmam Resid...."
            ;;


       4)
            echo "Estekhrag Format Hay Pakhsh Online ..."
            read -r -p "Lotfan Link Site Ra Vared Konid: " ONLINE_URL
            echo "Link Site: $ONLINE_URL"

            # تابعی برای استخراج لینک‌ها
            extract_links() {
                local url=$1
                local pattern=$2
          curl -s -f -A "$RANDOM_USER_AGENT" "$url" | grep -Eo "$pattern"
            }
echo "Using User-Agent: $RANDOM_USER_AGENT"      
            # m3u8 (HLS)
            echo "Extracting m3u8 links..."
            extract_links "$ONLINE_URL" 'https?://[^"]+\.m3u8' "$RANDOM_USER_AGENT"

            # mpd (MPEG-DASH)
            echo "Extracting mpd links..."
            extract_links "$ONLINE_URL" 'https?://[^"]+\.mpd' "$RANDOM_USER_AGENT"

            # f4m (HDS)
            echo "Extracting f4m links..."
            extract_links "$ONLINE_URL" 'https?://[^"]+\.f4m' "$RANDOM_USER_AGENT"

            # ism/Manifest
            echo "Extracting ism/Manifest links..."
            extract_links "$ONLINE_URL" 'https?://[^"]+\.ism/Manifest' "$RANDOM_USER_AGENT"

           # MPEG-TS
            echo "Extracting ts links..."
            extract_links "$ONLINE_URL" 'https?://[^"]+\.ts' "$RANDOM_USER_AGENT"

           # VP9/VP8(WebM)
            echo "Extracting webm links..."
            extract_links "$ONLINE_URL" 'https?://[^"]+\.webm' "$RANDOM_USER_AGENT"

          # MP4
            echo "Extracting mp4 links..."
            extract_links "$ONLINE_URL" 'https?://[^"]+\.mp4' "$RANDOM_USER_AGENT"

          # AVI
            echo "Extracting avi links..."
            extract_links "$ONLINE_URL" 'https?://[^"]+\.avi' "$RANDOM_USER_AGENT"

          # MOV
            echo "Extracting mov links..."
            extract_links "$ONLINE_URL" 'https?://[^"]+\.mov' "$RANDOM_USER_AGENT"

          # WMV
            echo "Extracting wmv links..."
            extract_links "$ONLINE_URL" 'https?://[^"]+\.wmv' "$RANDOM_USER_AGENT"
            ;;

  
        5)
            echo "Khorooj Az Barname."
            exit 0
            ;;

        *)
            echo "Gozine Na-Moshakhas."
            ;;
    esac
done
