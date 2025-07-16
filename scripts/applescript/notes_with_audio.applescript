on run argv
    if (count of argv) < 2 then
        return "Error: Usage: osascript notes_with_audio.applescript <command> <args...>"
    end if
    
    set cmd to item 1 of argv
    
    if cmd is "check_or_create" then
        if (count of argv) < 2 then
            return "Error: Usage: check_or_create <note_title>"
        end if
        
        set noteTitle to item 2 of argv
        
        tell application "Notes"
            -- 直接在所有笔记中查找
            set foundNote to missing value
            repeat with n in notes
                if name of n is noteTitle then
                    set foundNote to n
                    exit repeat
                end if
            end repeat
            
            -- 如果笔记不存在，创建新笔记
            if foundNote is missing value then
                -- 尝试在"闪念笔记"文件夹中创建
                try
                    set targetFolder to folder "闪念笔记"
                    set newNote to make new note at targetFolder with properties {name:noteTitle, body:"<div><h1>" & noteTitle & "</h1></div><div><br></div>"}
                on error
                    -- 如果文件夹不存在，在第一个可用的文件夹中创建
                    set newNote to make new note with properties {name:noteTitle, body:"<div><h1>" & noteTitle & "</h1></div><div><br></div>"}
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
                
                -- 添加换行
                set body of foundNote to currentBody & "<div><br></div>"
                
                -- 添加音频文件作为附件
                try
                    -- 创建别名对象（使用 HFS 路径）
                    set audioFile to audioFilePath as POSIX file as alias
                    
                    -- 创建附件
                    make new attachment at end of foundNote with properties {file:audioFile}
                    
                    -- 等待附件添加完成
                    delay 1
                on error errMsg
                    return "Error adding audio: " & errMsg
                end try
                
                -- 获取更新后的内容（包含附件）
                set updatedBody to body of foundNote
                
                -- 添加转录文本
                set body of foundNote to updatedBody & "<div>" & textContent & "</div>"
                
                -- 添加分隔符
                set finalBody to body of foundNote
                set body of foundNote to finalBody & "<div>####</div>"
                
                return "success"
            else
                return "Error: Note not found"
            end if
        end tell
        
    else
        return "Error: Unknown command: " & cmd
    end if
end run