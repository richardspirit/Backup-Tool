Import-Module ShowUI
Import-Module ScheduledTasks

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[System.Windows.Forms.Application]::EnableVisualStyles()

$file = [system.drawing.image]::fromfile('C:\Users\sql_svc\Desktop\backup2.gif')
[array]$DropDownArray = "Monthly", "Weekly", "Daily", "Hourly"
$minArray = @("00","01","02","03","04","05","06","07","08","09" + 10..59)
$hourArray = @(0..12)
$amPm = "Am", "Pm", "24Hr"

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

function openBkpSched
{
	$bkpSched.Add_Shown({$bkpSched.Activate()})
	[void] $bkpSched.ShowDialog()
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

function Create-Job
{
	$jobName = $txtSchName.text
	$interval = $DropDown.Text
	$hour = $drpHours.Text
	$min = $drpMin.Text
	$dtmDate=$objCalendar.SelectionStart

	if ($dtmDate)
		{
			write-host $dtmDate.ToShortDateString()
		}
	
	
	
	write-host $hour
	write-host $min
	write-host $interval
	write-host $jobName
}

$drpAmPm_SelectedIndexChanged=
{
   if ($drpAmPm.Text -eq "24Hr")
   {
		$envnames = @("00","01","02","03","04","05","06","07","08","09" + 10..24)
   } else 
   {
		$envnames = @(1..12)
   }
   $drpHours.DataSource = $envnames
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
$bkpForm.Size = New-Object System.Drawing.Size(1000,500) 
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
$txtCatExec.Location = New-Object System.Drawing.Size(280,170) 
$txtCatExec.Size = New-Object System.Drawing.Size(200,23) 
$bkpForm.Controls.Add($txtCatExec)

$lblCatExec = New-Object System.Windows.Forms.Label
$lblCatExec.Location = New-Object System.Drawing.Size(280,150)
$lblCatExec.Size = New-Object System.Drawing.Size(260,20)
$lblCatExec.Text = "Select HPStoreOnceForMSSQL.exe Location"
$bkpForm.Controls.Add($lblCatExec)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Location = New-Object System.Drawing.Size(480,170)
$btnBrowse.Size = New-Object System.Drawing.Size(75,21)
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
$btnExit2.Location = New-Object System.Drawing.Size(870,400)
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
$txtList.Location = New-Object System.Drawing.Size(10,230) 
$txtList.Size = New-Object System.Drawing.Size(850,200) 
$bkpForm.Controls.Add($txtList)

$pictureBox = new-object Windows.Forms.PictureBox
$pictureBox.Location = New-Object System.Drawing.Size(560,0)
$pictureBox.Width = 420
$pictureBox.Height = 225
$pictureBox.Image = $file;
$bkpForm.controls.add($pictureBox)

$btnSchedule = New-Object System.Windows.Forms.Button
$btnSchedule.Location = New-Object System.Drawing.Size(870,350)
$btnSchedule.Size = New-Object System.Drawing.Size(75,23)
$btnSchedule.Text = "Schedule"
$btnSchedule.Add_Click({openBkpSched})
$bkpForm.Controls.Add($btnSchedule)

$bkpSched = New-Object System.Windows.Forms.Form 
$bkpSched.Text = "Backup Solution"
$bkpSched.Size = New-Object System.Drawing.Size(265,500) 
$bkpSched.StartPosition = "CenterScreen"
$bkpSched.KeyPreview = $True
$bkpSched.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objListBox.SelectedItem;$bkpSched.Close()}})
$bkpSched.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$bkpSched.Close()}}) 

$btnExit3 = New-Object System.Windows.Forms.Button
$btnExit3.Location = New-Object System.Drawing.Size(150,400)
$btnExit3.Size = New-Object System.Drawing.Size(75,23)
$btnExit3.Text = "Exit"
$btnExit3.Add_Click({$bkpSched.Close()})
$bkpSched.Controls.Add($btnExit3)

$objCalendar = New-Object System.Windows.Forms.MonthCalendar 
$objCalendar.Location = New-Object System.Drawing.Size(10,200)
$objCalendar.ShowTodayCircle = $False
$objCalendar.MaxSelectionCount = 1
$objCalendar.MinDate = Get-Date
$bkpSched.Controls.Add($objCalendar) 

$lblSchName = New-Object System.Windows.Forms.Label
$lblSchName.Location = New-Object System.Drawing.Size(10,10)
$lblSchName.Size = New-Object System.Drawing.Size(100,20)
$lblSchName.Text = "Schedule Name"
$bkpSched.Controls.Add($lblSchName)

$txtSchName = New-Object System.Windows.Forms.RichTextBox 
$txtSchName.Location = New-Object System.Drawing.Size(10,30) 
$txtSchName.Size = New-Object System.Drawing.Size(225,20) 
$bkpSched.Controls.Add($txtSchName)

$DropDown = new-object System.Windows.Forms.ComboBox
$DropDown.Location = new-object System.Drawing.Size(40,80)
$DropDown.Size = new-object System.Drawing.Size(130,30)
$bkpSched.Controls.Add($DropDown)

ForEach ($Item in $DropDownArray){
     [void] $DropDown.Items.Add($Item)
}

$lblInterval = New-Object System.Windows.Forms.Label
$lblInterval.Location = New-Object System.Drawing.Size(40,60)
$lblInterval.Size = New-Object System.Drawing.Size(100,20)
$lblInterval.Text = "Interval"
$bkpSched.Controls.Add($lblInterval)

$lblHours = New-Object System.Windows.Forms.Label
$lblHours.Location = New-Object System.Drawing.Size(20,110)
$lblHours.Size = New-Object System.Drawing.Size(50,20)
$lblHours.Text = "Hour:"
$bkpSched.Controls.Add($lblHours)

$drpHours = new-object System.Windows.Forms.ComboBox
$drpHours.Location = new-object System.Drawing.Size(20,130)
$drpHours.Size = new-object System.Drawing.Size(45,30)
$bkpSched.Controls.Add($drpHours)

ForEach ($Item in $hourArray){
     [void] $drpHours.Items.Add($Item)
}

$lblMin = New-Object System.Windows.Forms.Label
$lblMin.Location = New-Object System.Drawing.Size(100,110)
$lblMin.Size = New-Object System.Drawing.Size(50,20)
$lblMin.Text = "Minute:"
$bkpSched.Controls.Add($lblMin)

$drpMin = new-object System.Windows.Forms.ComboBox
$drpMin.Location = new-object System.Drawing.Size(100,130)
$drpMin.Size = new-object System.Drawing.Size(45,30)
$bkpSched.Controls.Add($drpMin)

ForEach ($Item in $minArray){
     [void] $drpMin.Items.Add($Item)
}

$cbxFirs = New-Object System.Windows.Forms.Checkbox
$cbxFirs.Location = New-Object System.Drawing.Size(30,170)
$cbxFirs.Size = New-Object System.Drawing.Size(70,20)
$cbxFirs.Text = "First day"
$bkpSched.Controls.Add($cbxFirs)

$cbxLast = New-Object System.Windows.Forms.Checkbox
$cbxLast.Location = New-Object System.Drawing.Size(140,170)
$cbxLast.Size = New-Object System.Drawing.Size(100,20)
$cbxLast.Text = "Last day"
$bkpSched.Controls.Add($cbxLast)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Location = New-Object System.Drawing.Size(30,400)
$btnSave.Size = New-Object System.Drawing.Size(75,23)
$btnSave.Text = "Save"
$btnSave.Add_Click({Create-Job})
$bkpSched.Controls.Add($btnSave)

$drpAmPm = new-object System.Windows.Forms.ComboBox
$drpAmPm.Location = new-object System.Drawing.Size(180,130)
$drpAmPm.Size = new-object System.Drawing.Size(45,30)
$bkpSched.Controls.Add($drpAmPm)
$drpAmPm.Add_SelectedIndexChanged($drpAmPm_SelectedIndexChanged)

ForEach ($Item in $amPm){
     [void] $drpAmPm.Items.Add($Item)
}

$lblAmPm = New-Object System.Windows.Forms.Label
$lblAmPm.Location = New-Object System.Drawing.Size(180,110)
$lblAmPm.Size = New-Object System.Drawing.Size(100,20)
$lblAmPm.Text = "Clock"
$bkpSched.Controls.Add($lblAmPm)

$btnSaveJob = New-Object System.Windows.Forms.Button
$btnSaveJob.Location = New-Object System.Drawing.Size(870,300)
$btnSaveJob.Size = New-Object System.Drawing.Size(75,23)
$btnSaveJob.Text = "Save"
$btnSaveJob.Add_Click({})
$bkpForm.Controls.Add($btnSaveJob)

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()

$x

