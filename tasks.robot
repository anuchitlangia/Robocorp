*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library         RPA.Browser
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.FileSystem
Library         RPA.HTTP
Library         RPA.Archive
Library         Dialogs
Library         RPA.Robocloud.Secrets
Library         RPA.core.notebook



# +
# #Steps- followed:
# 1. Open the website
# 2. Open a dialog box asking for url for downloading the csv file
# 3. Use the csv file to create the robot details in website
# 4. After dataentry operations, save the reciept in pdf file format 
# 5. Take the screenshot of Robot and add the robot to given pdf file.
# 6. Zip all receipts and save in output directory
# 7. Close the website
# -

*** Keywords ***
Open The Intranet Website
  ${website}=  Get Secret  website
    Open Available Browser  ${website}[url]
    Maximize Browser Window

***Keywords***
Remove and add directory
    [Arguments]  ${folder}
    Remove Directory  ${folder}  True
    Create Directory  ${folder}

***Keywords***
Intialize   
    Remove File  ${CURDIR}${/}orders.csv
    ${reciept_folder}=  Does Directory Exist  ${CURDIR}${/}reciepts
    ${robots_folder}=  Does Directory Exist  ${CURDIR}${/}robots
    Run Keyword If  '${reciept_folder}'=='True'  Remove and add directory  ${CURDIR}${/}reciepts  ELSE  Create Directory  ${CURDIR}${/}reciepts
    Run Keyword If  '${robots_folder}'=='True'  Remove and add directory  ${CURDIR}${/}robots  ELSE  Create Directory  ${CURDIR}${/}robots

*** Keywords ***
Close the modal
    Wait Until Page Contains Element  //button[@class="btn btn-dark"]
    Click Button  //button[@class="btn btn-dark"]
    

***Keywords***
Download the csv file
    ${file_url}=  Get Value From User  Please enter the csv file url  https://robotsparebinindustries.com/orders.csv  
    Download  ${file_url}  orders.csv
    Sleep  2 seconds

***Keywords***
Read the order csv file
    ${data}=  Read Table From Csv  ${CURDIR}${/}orders.csv  header=True
    Return From Keyword  ${data}

*** Keywords ***
Fill And Submit The Form
     [Arguments]  ${row}
    Close the modal
    Select From List By Value  //select[@name="head"]  ${row}[Head]
    Click Element  //input[@value="${row}[Body]"]
    Input Text  //input[@placeholder="Enter the part number for the legs"]  ${row}[Legs]
    Input Text  //input[@placeholder="Shipping address"]  ${row}[Address] 
    Click Button  //button[@id="preview"]
    Wait Until Page Contains Element  //div[@id="robot-preview-image"]
    Sleep  5 seconds
    Click Button  //button[@id="order"]
    Sleep  5 seconds

***Keywords***
Close and start Browser before another transaction
    Close Browser
    Open the website
    Continue For Loop

*** Keywords ***
Check Receipt for processed data 
    FOR  ${i}  IN RANGE  ${100}
        ${alert}=  Is Element Visible  //div[@class="alert alert-danger"]  
        Run Keyword If  '${alert}'=='True'  Click Button  //button[@id="order"] 
        Exit For Loop If  '${alert}'=='False'       
    END
    
    Run Keyword If  '${alert}'=='True'  Close and start Browser before another transaction 

***Keywords***
Final Receipts
    [Arguments]  ${row} 
    Sleep  5 seconds
    ${reciept_data}=  Get Element Attribute  //div[@id="receipt"]  outerHTML
    Html To Pdf  ${reciept_data}  ${CURDIR}${/}reciepts${/}${row}[Order number].pdf
    Screenshot  //div[@id="robot-preview-image"]  ${CURDIR}${/}robots${/}${row}[Order number].png 
    Add Watermark Image To Pdf  ${CURDIR}${/}robots${/}${row}[Order number].png  ${CURDIR}${/}reciepts${/}${row}[Order number].pdf  ${CURDIR}${/}reciepts${/}${row}[Order number].pdf 
    Click Button  //button[@id="order-another"]

***Keywords***
Processing the orders
    [Arguments]  ${data}
    FOR  ${row}  IN  @{data}    
        Fill And Submit The Form  ${row}
        Check Receipt for processed data 
        Final Receipts  ${row}      
    END 

***Keywords***
Zip the reciepts folder
    Archive Folder With Zip  ${CURDIR}${/}reciepts  ${OUTPUT_DIR}${/}reciepts.zip

*** Tasks ***
Order Processing Bot 
    Intialize
    Download the csv file
    ${data}=  Read the order csv file
    Open The Intranet Website
    Processing the orders  ${data}
    Zip the reciepts folder
    [Teardown]  Close Browser





