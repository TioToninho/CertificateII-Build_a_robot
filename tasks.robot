# +
*** Settings ***
Documentation      Orders robots from RobotSpareBin Industries Inc.
...                Saves the order HTML receipt as a PDF file.
...                Saves the screenshot of the ordered robot.
...                Embeds the screenshot of the robot to the PDF receipt.
...                Creates ZIP archive of the receipts and the images.
...                GitHub: TioToninho

Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         OperatingSystem
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.Archive
Library         RPA.Dialogs
Library         RPA.Robocloud.Secrets
# -
*** Variables ***
${file_name}=            orders.csv
${download_dir}=         ${CURDIR}${/}Downloads
${receipts_dir}=         ${CURDIR}${/}Receipts
${file_name_dir}=        ${download_dir}${/}${file_name}

# +
*** Keywords ***
Create Folder and Open Site
    Create Directory    ${download_dir}
    Create Directory    ${receipts_dir}
    ${url}=    Get Secret    website
    Open Chrome Browser     ${url}[url]
    Maximize Browser Window
    Wait Until Keyword Succeeds     30 sec   5 sec   Click Button When Visible   xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Download CSV
    Set Download Directory  ${download_dir}
    Download    https://robotsparebinindustries.com/orders.csv  target_file=${download_dir}  verify=True  overwrite=True
    Wait Until Keyword Succeeds     100 sec   5 sec   File Should Exist   ${file_name_dir}

Fill and Order
    ${orders}=      Read Table From Csv    ${file_name_dir}
    Add heading        Name the robot file
    Add text input    robotName    label=Name
    ${receipt_name}=    Run dialog
    
    FOR    ${order}    IN    @{orders}
        Select From List By Value   id:head     ${order}[Head]
        Click Element When Visible  id:id-body-${order}[Body]
        Input Text    xpath://*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
        Input Text    xpath://*[@id="root"]/div/div[1]/div/div[1]/form/div[4]/input    ${order}[Address]
        Click Element When Visible  id:preview
        FOR     ${i}    IN RANGE    100
            Click Element When Visible      id:order
            Sleep   2s
            ${check}=         Is Element Visible      id:receipt
            Exit For Loop If        ${check}
        END
        ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
        Html To Pdf    ${receipt_html}    ${download_dir}${/}receipt_${order}[Order number]${receipt_name.robotName}.pdf
        Screenshot    id:robot-preview-image    ${download_dir}${/}robot${order}[Order number].png
        Open Pdf    ${download_dir}${/}receipt_${order}[Order number]${receipt_name.robotName}.pdf
        ${robotPNG}=     Create List    ${download_dir}${/}robot${order}[Order number].png
        ...     ${download_dir}${/}receipt_${order}[Order number]${receipt_name.robotName}.pdf
        Add Files To Pdf    ${robotPNG}     ${download_dir}${/}receipt_${order}[Order number]${receipt_name.robotName}.pdf
        Close Pdf   ${download_dir}${/}receipt_${order}[Order number]${receipt_name.robotName}.pdf
        Move File    ${download_dir}${/}receipt_${order}[Order number]${receipt_name.robotName}.pdf     ${receipts_dir}
        Click Element When Visible  id:order-another
        Wait Until Keyword Succeeds     30 sec   5 sec   Click Button When Visible   xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    END
    Archive Folder With Zip     ${receipts_dir}  receipts.zip

Close and Log out
    Close Browser
# -

*** Tasks ***
Build a Robot
    Create Folder and Open Site
    Download CSV
    Fill and Order
    Close and Log out
