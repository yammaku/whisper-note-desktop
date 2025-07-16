on run argv
    if (count of argv) < 2 then
        return "Error: Usage: osascript notes_embed_audio.applescript <command> <args...>"
    end if
    
    set cmd to item 1 of argv
    
    if cmd is "check_or_create" then
        if (count of argv) < 2 then
            return "Error: Usage: check_or_create <note_title>"
        end if
        
        set noteTitle to item 2 of argv
        
        tell application "Notes"
            set foundNote to missing value
            repeat with n in notes
                if name of n is noteTitle then
                    set foundNote to n
                    exit repeat
                end if
            end repeat
            
            if foundNote is missing value then
                try
                    set targetFolder to folder "闪念笔记"
                    set newNote to make new note at targetFolder with properties {name:noteTitle, body:noteTitle}
                on error
                    set newNote to make new note with properties {name:noteTitle, body:noteTitle}
                end try
                return "created"
            else
                return "exists"
            end if
        end tell
        
    else if cmd is "append_with_audio" then
        if (count of argv) < 4 then
            return "Error: Usage: append_with_audio <note_title> <audio_file_path> <text>"
        end if
        
        set noteTitle to item 2 of argv
        set audioFilePath to item 3 of argv
        set textContent to item 4 of argv
        
        -- 创建临时的HTML文件包含音频和文本
        set tempHTMLPath to "/tmp/temp_note_content.html"
        set audioFileName to do shell script "basename " & quoted form of audioFilePath
        
        -- 构建HTML内容
        set htmlContent to "<!DOCTYPE html><html><body>"
        set htmlContent to htmlContent & "<br>"
        
        -- 添加音频播放器
        set htmlContent to htmlContent & "<p>🎵 " & audioFileName & "</p>"
        set htmlContent to htmlContent & "<audio controls><source src='file://" & audioFilePath & "' type='audio/mpeg'>Your browser does not support the audio element.</audio>"
        set htmlContent to htmlContent & "<br><br>"
        
        -- 添加转录文本
        set htmlContent to htmlContent & "<p>" & textContent & "</p>"
        set htmlContent to htmlContent & "<hr>"
        set htmlContent to htmlContent & "</body></html>"
        
        -- 写入临时HTML文件
        do shell script "echo " & quoted form of htmlContent & " > " & tempHTMLPath
        
        -- 在浏览器中打开并复制
        tell application "Safari"
            activate
            open location "file://" & tempHTMLPath
            delay 2
            
            -- 全选并复制
            tell application "System Events"
                keystroke "a" using command down
                delay 0.5
                keystroke "c" using command down
                delay 0.5
            end tell
        end tell
        
        -- 粘贴到Notes
        tell application "Notes"
            set foundNote to missing value
            repeat with n in notes
                if name of n is noteTitle then
                    set foundNote to n
                    exit repeat
                end if
            end repeat
            
            if foundNote is not missing value then
                activate
                show foundNote
                delay 1
                
                -- 移动到笔记末尾
                tell application "System Events"
                    keystroke (key code 125) using command down -- Command + 下箭头
                    delay 0.5
                    keystroke "v" using command down -- 粘贴
                end tell
                
                return "success"
            else
                return "Error: Note not found"
            end if
        end tell
        
    else
        return "Error: Unknown command: " & cmd
    end if
end run