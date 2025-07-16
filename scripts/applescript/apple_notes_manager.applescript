on run argv
    if (count of argv) < 2 then
        return "Error: Usage: osascript apple_notes_manager.applescript <command> <args...>"
    end if
    
    set cmd to item 1 of argv
    
    if cmd is "check_or_create" then
        -- 检查笔记是否存在，不存在则创建
        if (count of argv) < 3 then
            return "Error: Usage: check_or_create <note_title> <folder_name>"
        end if
        
        set noteTitle to item 2 of argv
        set folderName to item 3 of argv
        
        tell application "Notes"
            -- 查找文件夹
            set targetFolder to missing value
            try
                set targetFolder to folder folderName
            on error
                -- 如果文件夹不存在，使用默认文件夹
                set targetFolder to default folder
            end try
            
            -- 查找笔记
            set foundNote to missing value
            repeat with n in notes of targetFolder
                if name of n is noteTitle then
                    set foundNote to n
                    exit repeat
                end if
            end repeat
            
            -- 如果笔记不存在，创建新笔记
            if foundNote is missing value then
                set newNote to make new note at targetFolder with properties {name:noteTitle, body:"<div><h1>" & noteTitle & "</h1></div><div><br></div>"}
                return "created"
            else
                return "exists"
            end if
        end tell
        
    else if cmd is "append_with_audio" then
        -- 添加音频和文本到笔记
        if (count of argv) < 4 then
            return "Error: Usage: append_with_audio <note_title> <audio_path> <text>"
        end if
        
        set noteTitle to item 2 of argv
        set audioPath to item 3 of argv
        set textContent to item 4 of argv
        
        tell application "Notes"
            set foundNote to missing value
            repeat with n in notes
                if name of n is noteTitle then
                    set foundNote to n
                    exit repeat
                end if
            end repeat
            
            if foundNote is not missing value then
                -- 获取当前内容
                set currentBody to body of foundNote
                
                -- 构建新内容
                set newContent to currentBody & "<div><br></div>"
                
                -- 添加音频引用
                set newContent to newContent & "<div>[音频: " & audioPath & "]</div>"
                
                -- 添加转录文本
                set newContent to newContent & "<div>" & textContent & "</div>"
                
                -- 添加分隔符
                set newContent to newContent & "<div>####</div>"
                
                -- 更新笔记
                set body of foundNote to newContent
                
                return "success"
            else
                return "Error: Note not found"
            end if
        end tell
        
    else
        return "Error: Unknown command: " & cmd
    end if
end run