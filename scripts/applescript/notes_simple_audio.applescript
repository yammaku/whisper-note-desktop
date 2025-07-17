on run argv
    if (count of argv) < 2 then
        return "Error: Usage: osascript notes_simple_audio.applescript <command> <args...>"
    end if
    
    set cmd to item 1 of argv
    
    if cmd is "check_or_create" then
        if (count of argv) < 2 then
            return "Error: Usage: check_or_create <note_title>"
        end if
        
        set noteTitle to item 2 of argv
        
        tell application "Notes"
            set foundNote to missing value
            
            -- 首先尝试获取Capture/閃念筆記文件夹
            try
                set captureFolder to folder "Capture"
                set targetFolder to folder "閃念筆記" of captureFolder
                -- 只在"閃念筆記"文件夹中查找
                repeat with n in notes of targetFolder
                    if name of n is noteTitle then
                        set foundNote to n
                        exit repeat
                    end if
                end repeat
            on error
                -- 如果文件夹不存在，则所有笔记中都不会有
                set foundNote to missing value
            end try
            
            if foundNote is missing value then
                try
                    -- 确保有Capture/閃念筆記文件夹结构
                    try
                        set captureFolder to folder "Capture"
                    on error
                        -- 如果Capture文件夹不存在，创建它
                        set captureFolder to make new folder with properties {name:"Capture"}
                    end try
                    
                    try
                        set targetFolder to folder "閃念筆記" of captureFolder
                    on error
                        -- 如果閃念筆記文件夹不存在，在Capture下创建它
                        set targetFolder to make new folder at captureFolder with properties {name:"閃念筆記"}
                    end try
                    
                    set newNote to make new note at targetFolder with properties {name:noteTitle, body:""}
                on error errMsg
                    -- 如果还是失败，在默认位置创建
                    set newNote to make new note with properties {name:noteTitle, body:""}
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
        
        -- 检查audioFilePath是否包含自定义文件名（格式：路径|文件名）
        if audioFilePath contains "|" then
            set AppleScript's text item delimiters to "|"
            set pathParts to text items of audioFilePath
            set audioFilePath to item 1 of pathParts
            set audioFileName to item 2 of pathParts
            set AppleScript's text item delimiters to ""
        else
            -- 获取音频文件名
            set audioFileName to do shell script "basename " & quoted form of audioFilePath
        end if
        
        tell application "Notes"
            set foundNote to missing value
            
            -- 只在Capture/閃念筆記文件夹中查找笔记
            try
                set captureFolder to folder "Capture"
                set targetFolder to folder "閃念筆記" of captureFolder
                repeat with n in notes of targetFolder
                    if name of n is noteTitle then
                        set foundNote to n
                        exit repeat
                    end if
                end repeat
            on error
                -- 文件夹不存在，笔记肯定也不存在
                set foundNote to missing value
            end try
            
            if foundNote is not missing value then
                -- 获取当前内容
                set currentBody to body of foundNote
                
                -- 查找标题结束的位置（</h1> 标签之后）
                set titleEnd to offset of "</h1>" in currentBody
                if titleEnd > 0 then
                    set titleEnd to titleEnd + 5 -- 包含 </h1> 本身
                    
                    -- 分割内容：标题部分和主体部分
                    set titlePart to text 1 thru titleEnd of currentBody
                    set bodyPart to ""
                    if titleEnd < length of currentBody then
                        set bodyPart to text (titleEnd + 1) thru -1 of currentBody
                    end if
                    
                    -- 构建新内容：标题 + 新内容 + 原有内容
                    set newContent to titlePart & "<br>"
                    
                    -- 添加文件名作为第一行
                    set newContent to newContent & "<p><strong>" & audioFileName & "</strong></p>"
                    
                    -- 添加转录文本（不添加音频链接）
                    set newContent to newContent & "<p>" & textContent & "</p>"
                    
                    -- 添加分隔符（四个井号）
                    set newContent to newContent & "<div>####</div>"
                    
                    -- 添加原有的主体内容
                    set newContent to newContent & bodyPart
                else
                    -- 如果找不到标题，就按原来的方式append到末尾
                    set newContent to currentBody & "<br>"
                    set newContent to newContent & "<p><strong>" & audioFileName & "</strong></p>"
                    set newContent to newContent & "<p>" & textContent & "</p>"
                    set newContent to newContent & "<div>####</div>"
                end if
                
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