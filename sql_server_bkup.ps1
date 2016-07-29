Import-Module ShowUI


[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 


function get-db-list
{
    
    
    $SQLServer = $objTextbox.Text
    $SqlQuery = "Select * from Sys.Databases"
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	
	if ($SQLServer -ne ""){
		try
		{
		$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName;Integrated Security = True" 
 
		$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
		$SqlCmd.CommandText = $SqlQuery
		$SqlCmd.Connection = $SqlConnection
 
		$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
		$SqlAdapter.SelectCommand = $SqlCmd
		
		$DataSet = New-Object System.Data.DataSet
        
		$SqlAdapter.Fill($DataSet)
		}
		catch
		{
			$wshell = New-Object -ComObject Wscript.Shell
			$wshell.Popup("Connection Error " + $_.Exception.ToString() ,0,"Done",0x1)
		}
		$SqlConnection.Close()
		$objListBox.Items.Clear()

		foreach ($row in $DataSet.Tables[0].Rows)
		{
			[void] $objListBox.Items.Add($($row[0]))
			
        
		}
	} else {$wshell = New-Object -ComObject Wscript.Shell

			$wshell.Popup("Enter Server Name",0,"Done",0x1)}
}

function openBkpFrm
{
	$database = $objListBox.SelectedItem
	
	$dbLabel.Text = $database
	$bkpForm.Add_Shown({$bkpForm.Activate()})
	[void] $bkpForm.ShowDialog()
}

Function Get-OpenFile($initialDirectory)
{ 
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
Out-Null

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.initialDirectory = $initialDirectory
$OpenFileDialog.filter = "(*.exe)|*.exe"
$OpenFileDialog.ShowDialog() | Out-Null
$OpenFileDialog.filename
$OpenFileDialog.ShowHelp = $true
}

function Set-Directory
{
	$inputFile=Get-OpenFile
	$txtCatExec.Text = $inputFile
}

function Backup-Command
{
	if ($rdbDiff.checked -eq $true){
		$bkpType = "WITH DIFFERENTIAL"
	}
	
	if ($rdbLog.checked -eq $true){
		$bkpLog = "LOG"
		}else{
			$bkpLog = 'DATABASE'
	}
	
	$bkpString =  "BACKUP " + $bkpLog + " [" + $database + "]" + " TO STORE=" + "'" + $user + ":" + $password + "@" + $server + "/" + $store + "' " + $bkpType + """"
	write-host $bkpType $bkpLog
	$txtList.clear()
	
	& $command -backup $bkpString | Out-String -Stream | foreach-object {
		$txtList.lines = $txtList.lines + $_
		$txtList.Select($txtList.Text.Length, 0)
		$txtList.ScrollToCaret()
		$bkpForm.Update()
	}
}

function Restore-Command
{
}

function List-Command
{
	$listString = '-store=' + "'" + $user + ":" + $password + "@" + $server + "/" + $store + "'"
	
	$txtList.clear()
	
	& $command -list $listString | Out-String -Stream | foreach-object {
		$txtList.lines = $txtList.lines + $_
		$txtList.Select($txtList.Text.Length, 0)
		$txtList.ScrollToCaret()
		$bkpForm.Update()
	}
}

function Build-Command
{
	$catCommand = $args[0]
	
	$user = $txtUser.Text
	$password = $txtPassword.Text
	$server = $SOServer.Text
	$store = $txtStore.Text
	$command = $txtCatExec.Text
	
	switch ($catCommand)
		{
			1 {Backup-Command}
			2 {"Restore"}
			3 {List-Command}
		}
	
}

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Backup Solution"
$objForm.Size = New-Object System.Drawing.Size(500,220) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objListBox.SelectedItem;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$objTextBox = New-Object System.Windows.Forms.TextBox 
$objTextBox.Location = New-Object System.Drawing.Size(10,40) 
$objTextBox.Size = New-Object System.Drawing.Size(260,20) 
$objForm.Controls.Add($objTextBox)

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(10,150)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({openBkpFrm})
$objForm.Controls.Add($OKButton)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Location = New-Object System.Drawing.Size(75,150)
$btnExit.Size = New-Object System.Drawing.Size(75,23)
$btnExit.Text = "Exit"
$btnExit.Add_Click({$objForm.Close()})
$objForm.Controls.Add($btnExit)

$slctServer = New-Object System.Windows.Forms.Button
$slctServer.Location = New-Object System.Drawing.Size(275,40)
$slctServer.Size = New-Object System.Drawing.Size(75,20)
$slctServer.Text = "Select"
$slctServer.Add_Click({get-db-list})
$objForm.Controls.Add($slctServer)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(280,20) 
$objLabel.Text = "Please select a server:"
$objForm.Controls.Add($objLabel)

$slctDB = New-Object System.Windows.Forms.Label
$slctDB.Location = New-Object System.Drawing.Size(10,65) 
$slctDB.Size = New-Object System.Drawing.Size(280,20) 
$slctDB.Text = "Please select a database:"
$objForm.Controls.Add($slctDB)  

$objListBox = New-Object System.Windows.Forms.ListBox 
$objListBox.Location = New-Object System.Drawing.Size(10,80) 
$objListBox.Size = New-Object System.Drawing.Size(260,20) 
$objListBox.Height = 80
$objForm.Controls.Add($objListBox)

$bkpForm = New-Object System.Windows.Forms.Form 
$bkpForm.Text = "Backup Solution"
$bkpForm.Size = New-Object System.Drawing.Size(600,400) 
$bkpForm.StartPosition = "CenterScreen"
$bkpForm.KeyPreview = $True
$bkpForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objListBox.SelectedItem;$bkpForm.Close()}})
$bkpForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$bkpForm.Close()}}) 

#Child form objects
$dbLabel = New-Object System.Windows.Forms.Label
$dbLabel.Location = New-Object System.Drawing.Size(10,10)
$dbLabel.Size = New-Object System.Drawing.Size(260,20)
$dbLabel.Text = $database
$bkpForm.Controls.Add($dbLabel)

$SOLabel = New-Object System.Windows.Forms.Label
$SOLabel.Location = New-Object System.Drawing.Size(10,40)
$SOLabel.Size = New-Object System.Drawing.Size(260,20)
$SOLabel.Text = "StoreOnce Server"
$bkpForm.Controls.Add($SOLabel)

$SOServer = New-Object System.Windows.Forms.TextBox 
$SOServer.Location = New-Object System.Drawing.Size(10,60) 
$SOServer.Size = New-Object System.Drawing.Size(260,20) 
$bkpForm.Controls.Add($SOServer)

$lblStore = New-Object System.Windows.Forms.Label
$lblStore.Location = New-Object System.Drawing.Size(10,80)
$lblStore.Size = New-Object System.Drawing.Size(260,20)
$lblStore.Text = "StoreOnce Store"
$bkpForm.Controls.Add($lblStore)

$txtStore = New-Object System.Windows.Forms.TextBox 
$txtStore.Location = New-Object System.Drawing.Size(10,100) 
$txtStore.Size = New-Object System.Drawing.Size(260,20) 
$bkpForm.Controls.Add($txtStore)

$gpbType = New-Object System.Windows.Forms.GroupBox
$gpbType.Location = New-Object System.Drawing.Size(10,120) #location of the group box (px) in relation to the primary window's edges (length, height)
$gpbType.size = New-Object System.Drawing.Size(150,100) #the size in px of the group box (length, height)
$gpbType.text = "Backup Types" #labeling the box
$bkpForm.Controls.Add($gpbType) #activate the group box

$rdbFull = New-Object System.Windows.Forms.RadioButton #create the radio button
$rdbFull.Location = new-object System.Drawing.Point(10,20) #location of the radio button(px) in relation to the group box's edges (length, height)
$rdbFull.size = New-Object System.Drawing.Size(85,20) #the size in px of the radio button (length, height)
$rdbFull.Checked = $true #is checked by default
$rdbFull.Text = "Full Backup" #labeling the radio button
$gpbType.Controls.Add($rdbFull) #activate the inside the group box

$rdbDiff = New-Object System.Windows.Forms.RadioButton #create the radio button
$rdbDiff.Location = new-object System.Drawing.Point(10,40) #location of the radio button(px) in relation to the group box's edges (length, height)
$rdbDiff.size = New-Object System.Drawing.Size(120,20) #the size in px of the radio button (length, height)
$rdbDiff.Checked = $false #is checked by default
$rdbDiff.Text = "Differential Backup" #labeling the radio button
$gpbType.Controls.Add($rdbDiff) #activate the inside the group box

$rdbLog = New-Object System.Windows.Forms.RadioButton #create the radio button
$rdbLog.Location = new-object System.Drawing.Point(10,60) #location of the radio button(px) in relation to the group box's edges (length, height)
$rdbLog.size = New-Object System.Drawing.Size(100,20) #the size in px of the radio button (length, height)
$rdbLog.Checked = $false #is checked by default
$rdbLog.Text = "Log Backup" #labeling the radio button
$gpbType.Controls.Add($rdbLog) #activate the inside the group box

$txtCatExec = New-Object System.Windows.Forms.TextBox 
$txtCatExec.Location = New-Object System.Drawing.Size(10,300) 
$txtCatExec.Size = New-Object System.Drawing.Size(260,23) 
$bkpForm.Controls.Add($txtCatExec)

$lblCatExec = New-Object System.Windows.Forms.Label
$lblCatExec.Location = New-Object System.Drawing.Size(10,280)
$lblCatExec.Size = New-Object System.Drawing.Size(260,20)
$lblCatExec.Text = "Select HPStoreOnceForMSSQL.exe Location"
$bkpForm.Controls.Add($lblCatExec)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Location = New-Object System.Drawing.Size(275,295)
$btnBrowse.Size = New-Object System.Drawing.Size(75,23)
$btnBrowse.Text = "Browse"
$btnBrowse.Add_Click({$inputFile = Set-Directory})
$bkpForm.Controls.Add($btnBrowse)

$lblUser = New-Object System.Windows.Forms.Label
$lblUser.Location = New-Object System.Drawing.Size(280,40)
$lblUser.Size = New-Object System.Drawing.Size(260,20)
$lblUser.Text = "StoreOnce User"
$bkpForm.Controls.Add($lblUser)

$txtUser = New-Object System.Windows.Forms.TextBox 
$txtUser.Location = New-Object System.Drawing.Size(280,60) 
$txtUser.Size = New-Object System.Drawing.Size(260,20) 
$bkpForm.Controls.Add($txtUser)

$lblPassword = New-Object System.Windows.Forms.Label
$lblPassword.Location = New-Object System.Drawing.Size(280,80)
$lblPassword.Size = New-Object System.Drawing.Size(260,20)
$lblPassword.Text = "StoreOnce Password"
$bkpForm.Controls.Add($lblPassword)

$txtPassword = New-Object System.Windows.Forms.TextBox 
$txtPassword.Location = New-Object System.Drawing.Size(280,100) 
$txtPassword.Size = New-Object System.Drawing.Size(260,20) 
$bkpForm.Controls.Add($txtPassword)

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Location = New-Object System.Drawing.Size(170,130)
$btnStart.Size = New-Object System.Drawing.Size(80,23)
$btnStart.Text = "Start Backup"
$btnStart.Add_Click({Build-Command 1})
$bkpForm.Controls.Add($btnStart)

$btnExit2 = New-Object System.Windows.Forms.Button
$btnExit2.Location = New-Object System.Drawing.Size(400,300)
$btnExit2.Size = New-Object System.Drawing.Size(75,23)
$btnExit2.Text = "Exit"
$btnExit2.Add_Click({$bkpForm.Close();$objForm.Close()})
$bkpForm.Controls.Add($btnExit2)

$btnList = New-Object System.Windows.Forms.Button
$btnList.Location = New-Object System.Drawing.Size(170,160)
$btnList.Size = New-Object System.Drawing.Size(80,23)
$btnList.Text = "List Backups"
$btnList.Add_Click({Build-Command 3})
$bkpForm.Controls.Add($btnList)

$btnRestore = New-Object System.Windows.Forms.Button
$btnRestore.Location = New-Object System.Drawing.Size(170,190)
$btnRestore.Size = New-Object System.Drawing.Size(80,23)
$btnRestore.Text = "Start Restore"
$btnRestore.Add_Click({Build-Command})
$bkpForm.Controls.Add($btnRestore)

$txtList = New-Object System.Windows.Forms.RichTextBox 
$txtList.Location = New-Object System.Drawing.Size(280,130) 
$txtList.Size = New-Object System.Drawing.Size(260,150) 
$bkpForm.Controls.Add($txtList)



$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()

$x

