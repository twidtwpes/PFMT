###CLEAR MAILBOX TEST LIST ON REFRESH
###'X' ON SERVER SELECT FORM DOES NOT CANCEL
###MODIFICATIONS ON PFMXS NEED TABSTOP
###NEED CHECK FOR PUBLIC FOLDERS ON 2010 AND 2013 TO VERIFY IF MIGRATION HAS BEEN DONE AS DOUBLE CHECK BEFORE STARTING
###ISSUE WITH SAVED PFMXS; RENAMING, SAVING, ETC.
###CONFIRM THAT THE MIGRATION PREVIOUS EXISTS IF CHOOSING TO RESUME
###DISABLE CONTROLS DURNING MIGRATION NEEDS TWEEKING BETWEEN STEPS
###WILL ERROR IF EXTERNAL MIGRATION NAME IS DIFFERENT
###CHANGE NON CROSS SCRIPT VARIABLES TO $SCRIPT FROM $GLOBAL
###GIVE OPTION TO CREATE 2013 MAILBOX IF NEEDED
###DISABLE FINALIZE BUTTON WHEN IN PROGRESS
###REMOVE MIGRATION AFTER COMPLETION-SAVE TO FILE
###ISSUE WITH RELEASE WHEN CHECKING PUBLIC FOLDER MAILBOXES-PUBLIC FOLDER TOOLS
###ISSUE WITH GETTING 2013 PUBLIC FOLDERS-PUBLIC FOLDER TOOLS

###NEED TO ADD THE FOLLOWING FEATURES:
######################################
#Migration Verification
#Migration Rollback
#Filtering for the public folder-to-public folder mailbox assignment page
cls
########################################################################
# Public Folder Migration Tool
# pfmtForm.ps1
# Version: 1.2.37
# Created By: Casey Walsh
# Created On: 11/3/2013 9:54 PM
# Description: Main form script for public folder migration from Exchange 2010 to Exchange 2013.
########################################################################

function CheckSTA{
	if([threading.thread]::CurrentThread.GetApartmentState() -eq "MTA"){
		& $env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe -sta $MyInvocation.ScriptName
		exit
	}
}

function ExpandBin{
	mkdir Bin
	expand Bin.cab -f:* Bin
}

function SetUpGlobalVariables{
	$Global:curpath=(Get-Location).path
	$Global:scripts=$False
	$Global:connected=$False
	$Global:curVersion=$null
	$Global:mappingFolder=""
	$Global:ConfigXML=""
	$Global:xmlfile=""
	$Global:logfile=""
	$Global:logcnt=1000
	$Global:exch13Server=""
	$Global:exchLegacyServer=""
	$Global:exch13Session=$null
	$Global:exchLegacySession=$null
	$Global:pfs=@()
	$Global:pfss=@()
	$Global:mxpf=@()
	$Global:currentDisplay=""
	$Global:migrationStep=0
	$Global:renameCnt=$null
	$Global:rename=$null
	$Global:saveMailboxes=@()
	$Global:folderMove=$null
	$Global:mxNodes=@()
	$Global:mxSource=$null
	$Global:mxAction=$null
	$Global:mxReturn=$null
	$Global:migResponse=$null
	$Global:rootMx=$null
	$Global:testMX=$null
	$Global:pubFolNodeFilterOptions=@("PSComputerName","RunspaceId","AgeLimit","EformsLocaleId","EntryId","FolderType","HasModerator","HasRules","HasSubFolders","HiddenFromAddressListsEnabled","Identity","IssueWarningQuota","IsValid","LocalReplicaAgeLimit","MailEnabled","MapiIdentity","MaxItemSize","Name","OriginatingServer","ParentPath","PerUserReadStateEnabled","ProhibitPostQuota","Replicas","ReplicationSchedule","RetainDeletedItemsFor","UseDatabaseAgeDefaults","UseDatabaseQuotaDefaults","UseDatabaseReplicationSchedule","UseDatabaseRetentionDefaults","AdminDisplayName","AssociatedItemCount","ContactCount","CreationTime","DatabaseName","DeletedItemCount","ExpiryTime","FolderPath","IsDeletePending","ItemCount","LastAccessTime","LastModificationTime","LastUserAccessTime","LastUserModificationTime","OwnerCount","ServerName","StorageGroupName","TotalAssociatedItemSize","TotalDeletedItemSize","TotalItemSize")
	$Global:pubFolMaiNodeFilterOptions=@("CopyChangesFrom","ResetChangeTracking","PSComputerName","PSShowComputerName","RunspaceId","AcceptMessagesOnlyFrom","AcceptMessagesOnlyFromDLMembers","AcceptMessagesOnlyFromSendersOrMembers","AddressBookPolicy","AddressListMembership","AdminDisplayVersion","Alias","AntispamBypassEnabled","ArbitrationMailbox","ArchiveDatabase","ArchiveDomain","ArchiveGuid","ArchiveName","ArchiveQuota","ArchiveRelease","ArchiveState","ArchiveStatus","ArchiveWarningQuota","AuditAdmin","AuditDelegate","AuditEnabled","AuditLogAgeLimit","AuditOwner","BypassModerationFromSendersOrMembers","CalendarLoggingQuota","CalendarRepairDisabled","CalendarVersionStoreDisabled","CustomAttribute1","CustomAttribute10","CustomAttribute11","CustomAttribute12","CustomAttribute13","CustomAttribute14","CustomAttribute15","CustomAttribute2","CustomAttribute3","CustomAttribute4","CustomAttribute5","CustomAttribute6","CustomAttribute7","CustomAttribute8","CustomAttribute9","Database","DefaultPublicFolderMailbox","DeliverToMailboxAndForward","DisabledArchiveDatabase","DisabledArchiveGuid","DisplayName","DistinguishedName","DowngradeHighPriorityMessagesEnabled","EmailAddresses","EmailAddressPolicyEnabled","EndDateForRetentionHold","ExchangeGuid","ExchangeSecurityDescriptor","ExchangeUserAccountControl","ExchangeVersion","ExtensionCustomAttribute1","ExtensionCustomAttribute2","ExtensionCustomAttribute3","ExtensionCustomAttribute4","ExtensionCustomAttribute5","Extensions","ExternalDirectoryObjectId","ExternalOofOptions","ForwardingAddress","ForwardingSmtpAddress","GrantSendOnBehalfTo","Guid","HasPicture","HasSpokenName","HiddenFromAddressListsEnabled","Identity","ImmutableId","IncludeInGarbageCollection","InPlaceHolds","IsExcludedFromServingHierarchy","IsLinked","IsMachineToPersonTextMessagingEnabled","IsMailboxEnabled","IsPersonToPersonTextMessagingEnabled","IsResource","IsRootPublicFolderMailbox","IsShared","IsSoftDeletedByDisable","IsSoftDeletedByRemove","IssueWarningQuota","IsValid","Languages","LastExchangeChangedTime","LegacyExchangeDN","LinkedMasterAccount","LitigationHoldDate","LitigationHoldEnabled","LitigationHoldOwner","MailboxMoveBatchName","MailboxMoveFlags","MailboxMoveRemoteHostName","MailboxMoveSourceMDB","MailboxMoveStatus","MailboxMoveTargetMDB","MailboxPlan","MailboxRelease","MailTip","MailTipTranslations","ManagedFolderMailboxPolicy","MaxBlockedSenders","MaxReceiveSize","MaxSafeSenders","MaxSendSize","MessageTrackingReadStatusEnabled","MicrosoftOnlineServicesID","ModeratedBy","ModerationEnabled","Name","ObjectCategory","ObjectClass","ObjectState","Office","OfflineAddressBook","OrganizationalUnit","OrganizationId","OriginatingServer","PartnerObjectId","PersistedCapabilities","PoliciesExcluded","PoliciesIncluded","PrimarySmtpAddress","ProhibitSendQuota","ProhibitSendReceiveQuota","ProtocolSettings","QueryBaseDN","QueryBaseDNRestrictionEnabled","RecipientLimits","RecipientType","RecipientTypeDetails","ReconciliationId","RecoverableItemsQuota","RecoverableItemsWarningQuota","RejectMessagesFrom","RejectMessagesFromDLMembers","RejectMessagesFromSendersOrMembers","RemoteAccountPolicy","RemoteRecipientType","RequireSenderAuthenticationEnabled","ResetPasswordOnNextLogon","ResourceCapacity","ResourceCustom","ResourceType","RetainDeletedItemsFor","RetainDeletedItemsUntilBackup","RetentionComment","RetentionHoldEnabled","RetentionPolicy","RetentionUrl","RoleAssignmentPolicy","RulesQuota","SamAccountName","SCLDeleteEnabled","SCLDeleteThreshold","SCLJunkEnabled","SCLJunkThreshold","SCLQuarantineEnabled","SCLQuarantineThreshold","SCLRejectEnabled","SCLRejectThreshold","SendModerationNotifications","ServerLegacyDN","ServerName","SharingPolicy","SimpleDisplayName","SingleItemRecoveryEnabled","SKUAssigned","StartDateForRetentionHold","ThrottlingPolicy","UMDtmfMap","UMEnabled","UsageLocation","UseDatabaseQuotaDefaults","UseDatabaseRetentionDefaults","UserCertificate","UserPrincipalName","UserSMimeCertificate","WhenChanged","WhenChangedUTC","WhenCreated","WhenCreatedUTC","WhenMailboxCreated","WhenSoftDeleted","WindowsEmailAddress","WindowsLiveID")
	$Global:badAttributes=@("Clone","Dispose","Equals","Validate","ToString","SuppressDisposeTracker","GetType","GetProperties","GetHashCode","GetDisposeTracker")
}

function PopUp($msg,[switch]$Fatal){
	if($Global:logfile -ne "" -and $msg -ne $null){AddLog $msg.replace("`r`n","") -f:$Fatal}
	$popupDialogTextBox.Text=$msg
	$popupForm.ShowDialog()| Out-Null
	if($Fatal){$pfmtForm.Close()}
}

function Progress($val,$msg,[switch]$e){
	if($val -ne $null){$progressBar.Value=$val}
	if($msg -ne $null){$messageLabel.Text=$msg}
	if($val -eq 100){
		$progressBar.ForeColor = [System.Drawing.Color]::FromArgb(255,6,176,37)
		$pfmtForm.Controls|?{$_.Name -ne "statusPanel" -and $_.Name -ne "filterPanel"}|%{
			$_.Enabled=$true
		}
	}else{
		$progressBar.ForeColor = [System.Drawing.Color]::FromArgb(255,9,36,107)
		$pfmtForm.Controls|?{$_.Name -ne "statusPanel" -and $_.Name -ne "filterPanel"}|%{
			$_.Enabled=$false
		}
	}
	$pfmtForm.Refresh()
	if($Global:logfile -ne "" -and $msg -ne $null){AddLog $msg -e:$e}
}

function EnableControls{
	if($Global:scripts){
		$connectButton.Enabled=$True
		if($Global:connected){$actionTreeView.Enabled=$True;$connectButton.Enabled=$False}
	}else{
		$connectButton.Enabled=$False
		$actionTreeView.Enabled=$False
	}
}

function LoadScripts{
	$cpath=$Global:curpath
	."${cpath}\Bin\scriptsForm.ps1"
	if($Global:mappingFolder -eq ""){Return}
	$check=$false
	$path=$Global:mappingfolder
	if($path.Substring($path.length-1) -ne "\"){$path+="\"}
	$Global:mappingfolder=$path
	if($path -eq "" -or (!(Test-Path -Path $path))){$check=$true}else{Progress 90}
	Progress -msg "Verifying..."
	if($check){
		Progress 0 "Failed to verify folders and scripts." -e
	}else{
		$Global:scripts=$True
		$displayMessageTextBox.Text = "`r`nSet the Exchange servers to use in the migration to proceed."
		Progress 90 "Creating logs..."
		GetCreateLogs
		Progress 100 "Done."
		SetServers
	}
}

function GetCreateLogs{
	if(!(Test-Path "$($Global:mappingFolder)PFMTLogs")){
		mkdir "$($Global:mappingFolder)PFMTLogs"
	}
	$dt=Get-Date -UFormat "%y%m%d%H%M%S"
	$Global:logfile="$($Global:mappingFolder)PFMTLogs\pfmt_${dt}.log"
	New-Item $Global:logfile -Type file
	AddLog "Log started: `"$($Global:logfile)`""
	AddLog "Date: $(Get-Date)"
	
	AddLog "Starting transcript: `"$($Global:mappingFolder)pfmt_transcript_$(date).txt`""
	Start-Transcript "$($Global:mappingFolder)PFMTLogs\pfmt_transcript_${dt}.txt"
	
	AddLog "Checking for PFMT config file: `"$($Global:mappingFolder)pfmt.config.xml`""
	if(Test-Path "$($Global:mappingFolder)pfmt.config.xml"){
		AddLog "Config file found. Loading data."
		$Global:xmlfile="$($Global:mappingFolder)pfmt.config.xml"
		$Global:ConfigXML=Import-Clixml $Global:xmlfile
		$Global:mappingFolder=$Global:ConfigXML.previousmigration.savelocation
		$Global:exch13Server=$Global:ConfigXML.previousmigration.exch13server
		$Global:exchLegacyServer=$Global:ConfigXML.previousmigration.exchlegacyserver
		if($Global:ConfigXML.previousmigration.migrationStep -gt 0){
			$Global:migResponse="previous"
			$cpath=$Global:curpath
			."${cpath}\Bin\migForm.ps1"
			if($Global:migResponse -ne "OK"){return}
			$Global:migrationStep=$Global:ConfigXML.previousmigration.migrationStep
		}

	if($Global:migrationStep -eq 9){$Global:migrationStep=8}
	$Global:rootMx=$Global:ConfigXML.previousmigration.rootMx

	}else{
		AddLog "No config file found."
		AddLog "Creating config file: `"$($Global:mappingFolder)pfmt.config.xml`""
		$xml=@{previousmigration=@{savelocation="";exch13server="";exchlegacyserver="";legacystructer="";legacystats="";legacyperms="";replace="";statsformap="";map="";migrationstarted="";migrationStep=0;rootMx=""}}
		$Global:xmlfile="$($Global:mappingFolder)pfmt.config.xml"
		$xml|Export-Clixml $Global:xmlfile
		$Global:ConfigXML=Import-Clixml $Global:xmlfile
		SetConfig "savelocation" $Global:mappingFolder
	}
}

function AddLog($add,[bool]$e,[bool]$f){
	$Global:logcnt++
	if($f){$log="PFMT:[FATAL]"}elseif($e){$log="PFMT:[ERROR]"}else{$log="PFMT:[LOG]"}
	$log+=":[$($Global:logcnt)]: ${add}"
	Add-Content $Global:logfile $log
}

function SetConfig($attribute,$value){
	Invoke-Expression "`$Global:ConfigXML.previousmigration.${attribute}=`"${value}`""
	$Global:ConfigXML|Export-Clixml $Global:xmlfile
}

function SetServers{
	$cpath=$Global:curpath
	."${cpath}\Bin\serversForm.ps1"
	if($Global:exch13Server -eq "" -or $Global:exchLegacyServer -eq ""){Return}
	$Global:connected=InitiateConnection
	Progress 10 "Verifying connections to Exchange..."
	if(!($Global:connected)){PopUp "`r`nUnknown error connecting to Exchange." -Fatal}
	Progress 40 "Updating config file..."
	SetConfig "exch13server" $Global:exch13Server
	SetConfig "exchlegacyserver" $Global:exchLegacyServer
	$displayMessageTextBox.Text="`r`nThe connections to the Exchange servers has been successful.`r`n`r`nSelect an item in the tree to proceed."
	Progress 70 "Checking previous migrations..."
	$gpfmr=@(Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-PublicFolderMigrationRequest})
	if($gpfmr.count -gt 0 -and $Global:migrationStep -eq $null){
		$Global:migResponse="unprevious"
		$cpath=$Global:curpath
		."${cpath}\Bin\migForm.ps1"
		if($Global:migResponse -eq "OK"){$Global:migrationStep=7}
	}
	Progress 100 "Done."
}

function InitiateConnection{
	Progress 14 "Removing any previous sessions and modules..."
	Get-PSSession|Remove-PSSession
	Get-Module|Remove-Module
	Progress 28 "Testing connection to Exchange 2013..."
	$request = [System.Net.WebRequest]::Create("http://$($Global:exch13Server)/powershell")
	$request.Method = "HEAD"
	$request.UseDefaultCredentials = $true
	$response = $request.GetResponse()
	if($response.StatusCode -ne "OK"){
		PopUp "`r`nCould not connect to Exchange 2013 Server."
		Progress 0 "Could not connect to Exchange 2013 Server."
		Return
	}
	Progress 42 "Importing Exchange 2013 session and module..."
	$sesop=New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
	$session=New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$($Global:exch13Server)/powershell" -SessionOption $sesop -WarningAction SilentlyContinue -ErrorVariable $er
	$null=Import-PSSession $session -AllowClobber -WarningAction SilentlyContinue -ErrorVariable $er
	Progress 100 "Done."
	if((Test-Path HKLM:\SOFTWARE\Microsoft\ExchangeServer\v14\Setup) -and (Test-Path ((get-itemproperty HKLM:\SOFTWARE\Microsoft\ExchangeServer\v14\Setup).MsiInstallPath + "bin\RemoteExchange.ps1"))){
		$global:remoteEx = (get-itemproperty HKLM:\SOFTWARE\Microsoft\ExchangeServer\v14\Setup).MsiInstallPath + "bin\RemoteExchange.ps1"
	}else{
		PopUp "`r`nYou must have the Exchange 2010 Management Tools`r`ninstalled in order to run this program." -Fatal
	}
	Progress 56 "Connecting to local Exchnage 2010 Mangement Shell..."
	."$($global:remoteEx)"
	Connect-ExchangeServer -ServerFqdn $Global:exchLegacyServer
	Progress 80 "Checking imported Exchange sessions..."
	if(!((Get-PSSession|?{$_.computername -eq "$($Global:exchLegacyServer)"}) -and (Get-PSSession|?{$_.computername -eq "$($Global:exch13Server)"}))){
		PopUp "`r`nUnknown error starting Exchange sessions." -Fatal
	}
	Progress 90 "Checking imported Exchange modules..."
	if(!((Get-Module|?{$_.description -like "*$($Global:exchLegacyServer)*"}) -and (Get-Module|?{$_.description -like "*$($Global:exch13Server)*"}))){
		PopUp "`r`nUnknown error importing Exchange modules." -Fatal
	}
	$Global:exch13Session=Get-PSSession|?{$_.computername -eq "$($Global:exch13Server)"}
	$Global:exchLegacySession=Get-PSSession|?{$_.computername -eq "$($Global:exchLegacyServer)"}
	Progress 100 "Done."
	Return $true
}

function SetObjectAvailability{
	$displayMessageTextBox.Visible = $True
	
	$connectButton.Enabled=$False
	$actionTreeView.Enabled=$False
	
	$filterPanel.Visible = $False
	
	$pubFolTreeView.Visible = $False
	$pubFolSplitter.Visible = $False
	$pubFolDataGridView.Visible = $False
	$pubFolLabel.Visible = $False
	
	$pubFolDatDataGridView.Visible = $False
	
	$pubFolMaiDataGridView.Visible = $False
	$pubFolMaiSplitter.Visible = $False
	$pubFolMaiAttDataGridView.Visible = $False

	$migPubFolTabControl.Visible = $False
	$pfmtForm.Refresh()
}

function SetMigrationPageAvailablity{
	if($Global:migrationStep -gt 4 -and $Global:migrationStep -lt 10){
		$pfmtForm.Controls|?{$_.Name -ne "statusPanel" -and $_.Name -ne "dispayPanel"}|%{
			$_.Enabled=$false
		}
	}
	SetConfig "migrationStep" $Global:migrationStep
	$migPubFolTabControl.Controls.Remove($snapshotTabPage)
	$migPubFolTabControl.Controls.Remove($replaceTabPage)
	$migPubFolTabControl.Controls.Remove($checkTabPage)
	$migPubFolTabControl.Controls.Remove($generateTabPage)
	$migPubFolTabControl.Controls.Remove($createTabPage)
	$migPubFolTabControl.Controls.Remove($assignTabPage)
	$migPubFolTabControl.Controls.Remove($startMigrationTabPage)
	$migPubFolTabControl.Controls.Remove($progressTabPage)
	$migPubFolTabControl.Controls.Remove($finalizeMigrationTabPage)
	$migPubFolTabControl.Controls.Remove($completedTabPage)
	switch($Global:migrationStep){
		0{$migPubFolTabControl.Controls.Add($snapshotTabPage)}
		1{$migPubFolTabControl.Controls.Add($replaceTabPage);reloadButtonClick}
		2{$migPubFolTabControl.Controls.Add($checkTabPage);GetPreviousMigrations}
		3{$migPubFolTabControl.Controls.Add($generateTabPage)}
		4{$migPubFolTabControl.Controls.Add($createTabPage);$migPubFolTabControl.Controls.Add($assignTabPage);$migPubFolTabControl.Controls.Add($startMigrationTabPage);GetCreateNodeTree}
		5{$migPubFolTabControl.Controls.Add($progressTabPage);$pfmtForm.Refresh();GetMigrationProgress}
		6{$migPubFolTabControl.Controls.Add($progressTabPage);$pfmtForm.Refresh();GetMigrationProgress}
		7{$migPubFolTabControl.Controls.Add($progressTabPage);$pfmtForm.Refresh();GetMigrationProgress}
		8{$migPubFolTabControl.Controls.Add($finalizeMigrationTabPage);GetMailboxesForFinalizeTest}
		9{$migPubFolTabControl.Controls.Add($finalizeMigrationTabPage);finalizeButtonClick}
		10{$migPubFolTabControl.Controls.Add($completedTabPage);CompletedMigration}
	}
	if($Global:migrationStep -gt 7){
		$progressTabPage.Controls.Remove($forceButton)
		$System_Drawing_Point = New-Object System.Drawing.Point
		$System_Drawing_Point.X = 10
		$System_Drawing_Point.Y = 440
		$forceButton.Location = $System_Drawing_Point
		$finalizeMigrationTabPage.Controls.Add($forceButton)
		$forceButton.Enabled = $false
	}
}

function SetFilter{
	$attributeComboBox.Items.Clear()
	switch($Global:currentDisplay){
			"pubFolNode"{
				$Global:pubFolNodeFilterOptions|sort|%{
					$attributeComboBox.Items.Add($_)|Out-Null
				}
			}
			"pubFolMaiNode"{
				$Global:pubFolMaiNodeFilterOptions|sort|%{
					$attributeComboBox.Items.Add($_)|Out-Null
				}
			}
	}
	$filterCheckBox.Checked=$false
	$resultSizeTextBox.Text = 1000
	$valueTextBox.Text="*"
	$comparisonComboBox.SelectedIndex = 2
	$attributeComboBox.SelectedIndex = 0
	SetFilterAvailability
}

function SetFilterAvailability{
	if($filterCheckBox.Checked){
		$filterControlPanel.Enabled=$True
		$filterRightPanel.Enabled=$True
	}else{
		$filterControlPanel.Enabled=$False
		$filterRightPanel.Enabled=$False
	}
}

function ApplyFilter{
	switch($Global:currentDisplay){
		"pubFolNode"{GetPubFolNodeTree}
		"pubFolDatNode"{GetPubFolDatDataGridView}
		"pubFolMaiNode"{GetPubFolMaiDataGridView}
		"createTreeView"{GetCreateNodeTree}
		"progressTabPage"{GetMigrationProgress}
		"replaceTabPage"{reloadButtonClick}
		"checkTabPage"{GetPreviousMigrations}
		"generateTabPage"{}
	}
}

function GetPubFolNodeTree{
	$pubFolTreeView.Nodes.Clear()
	$pubFolDataGridView.Rows.Clear()
	Progress 50 "Setting up public folder form..."
	$displayMessageTextBox.Visible = $False
	$filterPanel.Visible = $True
	$pubFolTreeView.Visible = $True
	$pubFolSplitter.Visible = $True
	$pubFolDataGridView.Visible = $True
	$pubFolLabel.Visible = $True
	Progress 50 "Getting public folder data..."
	$Global:pfs=@(Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolder \ -Recurse})
	$Global:pfss=Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolderStatistics}
	Progress 70 "Getting filter settings..."
	$Global:pfs=$Global:pfs|?{$_.name -ne "ipm_subtree"}|Sort-Object Identity
	Invoke-Expression "`$p=`$Global:pfs[0].$($attributeComboBox.Text)"
	if(($filterCheckBox.Checked) -and $p -eq $null){
		$filter="`$Global:pfss=@(`$Global:pfss|?`{`$_.$($attributeComboBox.Text)"
		switch($comparisonComboBox.Text){
			"Equals"{$filter+=" -eq "}
			"Does Not Equal"{$filter+=" -ne "}
			"Is Like"{$filter+=" -like "}
			"Greater Than"{$filter+=" -gt "}
			"Less Than"{$filter+=" -lt "}
		}
		$filter+="`"$($valueTextBox.Text)`"`})"
		Progress 70 "Applying filter..."
		Invoke-Expression $filter
		if($resultSizeTextBox.Text -ne "0"){
			$Global:rs=$resultSizeTextBox.Text
			$Global:pfss=0..($rs-1)|%{$Global:pfss[$_]}
		}
		$pftemp=@()
		foreach($s in $Global:pfss){
			$pftemp+=@($Global:pfs|?{"$($_.parentpath)\$($_.name)" -eq "\$($s.folderpath)"})
		}
		$Global:pfs=$pftemp
	}elseif($filterCheckBox.Checked){
		$filter="`$Global:pfs=@(`$Global:pfs|?`{`$_.$($attributeComboBox.Text)"
		switch($comparisonComboBox.Text){
			"Equals"{$filter+=" -eq "}
			"Does Not Equal"{$filter+=" -ne "}
			"Is Like"{$filter+=" -like "}
			"Greater Than"{$filter+=" -gt "}
			"Less Than"{$filter+=" -lt "}
		}
		$filter+="`"$($valueTextBox.Text)`"`})"
		Progress 70 "Applying filter..."
		Invoke-Expression $filter
		if($resultSizeTextBox.Text -ne "0"){
			$rs=$resultSizeTextBox.Text
			$Global:pfs=0..($rs-1)|%{$Global:pfs[$_]}
		}
	}
	$Global:pfs+=@($null,$null)
	$Global:pfs|?{$_ -ne $null}|%{
		$path=$_.identity.tostring().split("\")
		$cmd="`$pubFolTreeView"
		foreach($node in $path){
			if($node -ne "" -and ([array]::indexof($path,$node)+1) -ne $path.count){
				Invoke-Expression "`$needed=${cmd}.Nodes['${node}']"
				if(!($needed)){
					Invoke-Expression "`$addto=${cmd}"
					$tag=$cmd.replace("`$pubFolTreeView","\").replace("Nodes['","").replace("'].Nodes['","\").replace("']","")+$node
					$TreeNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
					$TreeNode.Tag=$tag
					$TreeNode.Name=$node
					$TreeNode.Text=$node
					$TreeNode.ImageIndex=5
					$TreeNode.SelectedImageIndex=5
					$TreeNode.ForeColor = [System.Drawing.Color]::FromArgb(255,128,128,128)
					$addto.Nodes.Add($TreeNode)|Out-Null
				}
				$cmd+=".Nodes['${node}']"
			}
		}
		Invoke-Expression "`$addto=${cmd}"
		$TreeNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
		$TreeNode.Tag=$_.identity
		$TreeNode.Name=$_.name
		$TreeNode.Text=$_.name
		if($_.mailenabled){$img=1}else{$img=0}
		$TreeNode.ImageIndex = $img
		$TreeNode.SelectedImageIndex = $img
		$addto.Nodes.Add($TreeNode)|Out-Null
	}
	Progress 100 "Done."
}

function GetPubFolNodeAttributes($node){
	if($pubFolTreeView.SelectedNode.Tag -ne $node){
		$select=$pubFolTreeView.Nodes|?{$_.Tag -eq $node}
		$pubFolTreeView.SelectedNode=$select
		$pfmtForm.Refresh()
		Progress 30 "Getting data for ${node}..."
		$pubFolDataGridView.Rows.Clear()
		Progress 40
		$pf=$Global:pfs|?{$_.identity -eq $node}
		if($pf -eq $null){
			Progress 10 "${node} is not a part of the filter..."
			Progress 0 "Done."
			Return
		}
		Progress 60
		$pf|Get-Member|%{
			if($Global:badAttributes -notcontains $_.name){
				$att=$_.name
				Invoke-Expression "`$val=`$pf.${att}"
				if($val.count -gt 0){$val=($val) -join ","}
				$pubFolDataGridView.Rows.Add($_.name,$val)
			}
		}
		
		Progress 40
		$pf=$Global:pfss|?{$_.identity -eq $node}
		Progress 60
		$pf|?{$_ -ne $null}|Get-Member|%{
			$keeprow=$true
			for($i=0;$i -le $pubFolDataGridView.Rows.Count-1;$i++){
				if($pubFolDataGridView.Rows[$i].Cells[0].Value -eq $_.name){$keeprow=$false}
			}
			if($Global:badAttributes -notcontains $_.name -and ($keeprow)){
				$att=$_.name
				Invoke-Expression "`$val=`$pf.${att}"
				if($val.count -gt 0){$val=($val) -join ","}
				$pubFolDataGridView.Rows.Add($_.name,$val)
			}
		}
		$pubFolLabel.Text=$node
		Progress 100 "Done."
	}
}

function GetPubFolDatDataGridView{
	Progress 40 "Updating form..."
	$displayMessageTextBox.Visible = $False
	$pubFolDatDataGridView.Visible = $True
	$pfmtForm.Refresh()
	$pubFolDatDataGridView.Rows.Clear()
	Progress 60 "Getting public folder database information..."
	$pfdb=Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolderDatabase -Status}
	$pfdb|%{
		$pubFolDatDataGridView.Rows.Add($_.name,$_.servername,$_.mounted,$_.databasesize,$_.maxitemsize)
	}
	Progress 90 "Clearing selected..."
	$pubFolDatDataGridView.ClearSelection()
	Progress 100 "Done."
}

function GetPubFolMaiDataGridView{
	Progress 40 "Updating form..."
	$displayMessageTextBox.Visible = $False
	$filterPanel.Visible = $True
	$pubFolMaiDataGridView.Visible = $True
	$pubFolMaiSplitter.Visible = $True
	$pubFolMaiAttDataGridView.Visible = $True
	$pfmtForm.Refresh()
	$pubFolMaiDataGridView.Rows.Clear()
	$pubFolMaiAttDataGridView.Rows.Clear()
	Progress 70 "Getting public folder data..."
	$Global:mxpf=Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-Mailbox -PublicFolder}
	Progress 60 "Getting filter..."
	$filter="`$Global:mxpf=`$Global:mxpf"
	if($filterCheckBox.Checked){
		$filter+="|?`{`$_.$($attributeComboBox.Text)"
		switch($comparisonComboBox.Text){
			"Equals"{$filter+=" -eq "}
			"Does Not Equal"{$filter+=" -ne "}
			"Is Like"{$filter+=" -like "}
			"Greater Than"{$filter+=" -gt "}
			"Less Than"{$filter+=" -lt "}
		}
		$filter+="`"$($valueTextBox.Text)`"`}"
		if($resultSizeTextBox.Text -ne "0"){
			$rs=$resultSizeTextBox.Text
			$Global:mxpf=0..($rs-1)|%{$Global:mxpf[$_]}
		}
		Progress 70 "Applying filter..."
		Invoke-Expression $filter
	}
	$name=@()
	$database=@()
	$mountedonserver=@()
	$servers=@()
	$Global:mxpf|%{
		$name+=@($_.name)
		$database+=@($_.database.tostring())
		$mountedonserver+=@("")
		$servers+=@("")
	}
	$mxdbs=Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-MailboxDatabase -Status}
	$database|select -uniq|%{
		$db=$_
		$mxdbatt=$mxdbs|?{$_.name -eq $db}
		$mxdb=$_
		for($i=0;$i -le $database.count-1;$i++){
			if($database[$i] -eq $_){
				$mountedonserver[$i]=$mxdbatt.mountedonserver
				$servers[$i]=($mxdbatt.servers) -join ","
			}
		}
	}
	
	for($i=0;$i -le $name.count-1;$i++){
		$pubFolMaiDataGridView.Rows.Add($name[$i],$database[$i],$mountedonserver[$i],$servers[$i])
	}
	Progress 90 "Clearing selected..."
	$pubFolMaiDataGridView.ClearSelection()
	Progress 100 "Done."
}

function GetPubFolMaiCellAttributes($event){
	for($i=0;$i -le $pubFolMaiDataGridView.Rows[$event.RowIndex].Cells.count-1;$i++){
		if($pubFolMaiDataGridView.Rows[$event.RowIndex].Cells[$i].Selected){
			$pubFolMaiDataGridView.Rows[$event.RowIndex].Selected=$True
			Return
		}
	}
	$row=$pubFolMaiDataGridView.Rows[$event.RowIndex].Cells[0].Value
	$pubFolMaiDataGridView.ClearSelection()
	Progress 30 "Getting data for ${row}..."
	$pubFolMaiAttDataGridView.Rows.Clear()
	$pfmx=$Global:mxpf|?{$_.name -eq $row}
	Progress 60
	$pfmx|Get-Member|%{
		if($Global:badAttributes -notcontains $_.name){
			$att=$_.name
			Invoke-Expression "`$val=`$pfmx.${att}"
			if($val.count -gt 0){$val=($val) -join ","}
			if($val.count -eq 0 -and $val.gettype() -eq [System.Collections.ArrayList]){$val=$null}
			$pubFolMaiAttDataGridView.Rows.Add($_.name,$val)
		}
	}
	Progress 90 "Waiting for release..."
}

function GetPubFolMaiCellSelect($event){
	Progress 95 "Clearing selected..."
	$pubFolMaiAttDataGridView.ClearSelection()
	$pubFolMaiDataGridView.Rows[$event.RowIndex].Selected=$True
	Progress 100 "Done."
}

function GetMigPubFolTabControl{
	SetMigrationPageAvailablity
	$displayMessageTextBox.Visible = $False
	$migPubFolTabControl.Visible = $True
}

function startButtonClick{
	Progress 40 "Exporting legacy public folder structure..."
	$pfdata=Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolder -Recurse}
	$pfdata|Export-CliXML "$($Global:mappingFolder)Legacy_PFStructure.xml"
	Progress 60 "Exporting legacy public folder statistics..."
	$pfdata=Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolderStatistics}
	$pfdata|Export-CliXML "$($Global:mappingFolder)Legacy_PFStatistics.xml"
	Progress 80 "Exporting legacy public folder permissions..."
	$pfdata=Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolder -Recurse | Get-PublicFolderClientPermission | Select-Object Identity,User -ExpandProperty AccessRights}
	$pfdata|Export-CliXML "$($Global:mappingFolder)Legacy_PFPerms.xml"
	Progress 85 "Saving config..."
	SetConfig "legacystructer" "$($Global:mappingFolder)Legacy_PFStructure.xml"
	SetConfig "legacystats" "$($Global:mappingFolder)Legacy_PFStatistics.xml"
	SetConfig "legacyperms" "$($Global:mappingFolder)Legacy_PFPerms.xml"
	Progress 90 "Verifying legacy exports..."
	if((Test-Path "$($Global:mappingFolder)Legacy_PFStructure.xml") -and (Test-Path "$($Global:mappingFolder)Legacy_PFStatistics.xml") -and (Test-Path "$($Global:mappingFolder)Legacy_PFPerms.xml")){
		if($Global:migrationStep -eq 0){$Global:migrationStep=1}
		SetMigrationPageAvailablity
		Progress 100 "Done."
	}else{
		Progress 0 "Error exporting legacy public folder environment data." -e
	}
}

function reloadButtonClick{
	$Global:currentDisplay="replaceTabPage"
	Progress 60 "Checking 2010 public folders for '\'..."
	$pfs=Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolderStatistics -ResultSize Unlimited}
	$pfs=@($pfs|?{$_.Name -like "*\*"})
	Progress 70 "Clearing replace list view..."
	$replaceListView.Clear()

	if($Global:rename -eq $null){$Global:renameCnt=$pfs.count}
	Progress 80 "Setting replace list view items..."
	$pfs|%{
		$ListViewItem = New-Object System.Windows.Forms.ListViewItem
		$ListViewItem.ImageIndex = 0
		$ListViewItem.Name = $_.Folderpath.replace("\$($_.Name)","")
		$ListViewItem.Text = $_.Name
		$replaceListView.Items.Add($ListViewItem)|Out-Null
	}
	Progress 100 "Done."
}

function CreateReplaceContextMenu($source, $event){
	if($event.Button -eq "Right" -and $source.FocusedItem.Bounds.Contains($event.Location)){
		$ContextMenuStrip=New-Object System.Windows.Forms.ContextMenuStrip
		$ContextMenuStrip.Items.Add("Rename").Add_Click({
			$Global:rename="$($replaceListView.FocusedItem.Text)"
			$cpath=$Global:curpath
			."${cpath}\Bin\renameForm.ps1"
			$pfpath="\$($replaceListView.FocusedItem.Name)".replace("$($replaceListView.FocusedItem.Text)","")
			$pf=Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolder -Recurse}
			$pf=$pf|?{$_.parentpath -eq $pfpath -and $_.name -eq "$($replaceListView.FocusedItem.Text)"}
			Invoke-Expression "`$pf|Invoke-Command -Session `$Global:exchLegacySession -ScriptBlock {Set-PublicFolder -Name `"$($Global:rename)`"}"
			reloadButtonClick
		})
		$source.ContextMenuStrip=$ContextMenuStrip
	}else{
		$source.ContextMenuStrip=$null
	}
}

function replaceButtonClick{
	SetConfig "replace" $replaceTextBox.Text
	Progress 40 "Checking legacy version..."
	Progress 60 "Re-checking 2010 public folders for '\'..."
	$pfs=Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolderStatistics -ResultSize Unlimited}
	$pfs=@($pfs|?{$_.Name -like "*\*"})
	Progress 70 "Renaming folders..."
	$pfs|%{
		$name=$_.name.replace("\",$replaceTextBox.Text)
		Invoke-Expression "`$_|Invoke-Command -Session `$Global:exchLegacySession -ScriptBlock {Set-PublicFolder -Name `"${name}`"}"
	}
	Progress 80 "Verifying public folder environment exports..."
	$pfs=Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolderStatistics -ResultSize Unlimited}
	$pfs=@($pfs|?{$_.Name -like "*\*"})
	if($Global:renameCnt -ne $pfs.count){
		Progress 90 "Re-exporting public folder environment data..."
		startButtonClick
	}
	Progress 100 "Done."
	if($Global:migrationStep -eq 1){$Global:migrationStep=2}
	SetMigrationPageAvailablity
}

function GetPreviousMigrations{
	$Global:currentDisplay="checkTabPage"
	$pfmxListView.Clear()
	Progress 50 "Checking if public folders are locked for migration..."
	$pflfm=Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-OrganizationConfig}
	if($pflfm.PublicFoldersLockedforMigration){
		$pflfmResultLabel.Text = "TRUE"
		$pflfmResultLabel.ForeColor = [System.Drawing.Color]::FromArgb(255,255,0,0)
	}else{
		$pflfmResultLabel.Text = "FALSE"
		$pflfmResultLabel.ForeColor = [System.Drawing.Color]::FromArgb(255,0,128,0)
	}
	Progress 60 "Checking for completed migration..."
	$pfmc=Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-OrganizationConfig}
	if($pfmc.PublicFolderMigrationComplete){
		$pfmcResultLabel.Text = "TRUE"
		$pfmcResultLabel.ForeColor = [System.Drawing.Color]::FromArgb(255,255,0,0)
	}else{
		$pfmcResultLabel.Text = "FALSE"
		$pfmcResultLabel.ForeColor = [System.Drawing.Color]::FromArgb(255,0,128,0)
	}
	Progress 80 "Getting public folder migration requests..."
	$pfmr=@(Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-PublicFolderMigrationRequest})
	if($pfmr[0].name -eq $null){
		$pfmrResultLabel.Text="none"
	}else{
		$pfmrResultLabel.Text=$pfmr[0].name
	}
	Progress 90 "Getting list of public folder mailboxes..."
	$pfmxs=@(Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-Mailbox -PublicFolder})
	$pfmxs|%{
		$ListViewItem = New-Object System.Windows.Forms.ListViewItem
		$ListViewItem.ImageIndex = 3
		$ListViewItem.Name = $_.Name
		$ListViewItem.Text = $_.Name
		$ListViewItem.Tag = "delete"
		$pfmxListView.Items.Add($ListViewItem)|Out-Null
	}
	Progress 100 "Done."
}

function CreateCheckContextMenu($source, $event){
	if($event.Button -eq "Right" -and $source.FocusedItem.Bounds.Contains($event.Location)){
		$ContextMenuStrip=New-Object System.Windows.Forms.ContextMenuStrip
		if($pfmxListView.FocusedItem.Tag -eq "delete"){
			$ContextMenuStrip.Items.Add("Save This Mailbox").Add_Click({
				$Global:saveMailboxes+=@("$($pfmxListView.FocusedItem.Text)")
				$pfmxListView.FocusedItem.ImageIndex=4
				$pfmxListView.FocusedItem.Tag="save"
			})
		}else{
			$ContextMenuStrip.Items.Add("Delete This Mailbox").Add_Click({
				$Global:saveMailboxes=$Global:saveMailboxes|?{$_ -ne "$($pfmxListView.FocusedItem.Text)"}
				$pfmxListView.FocusedItem.ImageIndex=3
				$pfmxListView.FocusedItem.Tag="delete"
			})
		}
		$source.ContextMenuStrip=$ContextMenuStrip
	}else{
		$source.ContextMenuStrip=$null
	}
}

function clearButtonClick{
	Progress 30 "Unlocking public folders and clearing completed migration..."
	Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Set-OrganizationConfig -PublicFoldersLockedforMigration:$false -PublicFolderMigrationComplete:$false}
	Progress 50 "Unlocking public folders and clearing completed migration..."
	Invoke-Command -Session $Global:exch13Session -ScriptBlock {Set-OrganizationConfig -PublicFoldersLockedforMigration:$false -PublicFolderMigrationComplete:$false}
	Progress 60 "Removing migration requests..."
	Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-PublicFolderMigrationRequest|Remove-PublicFolderMigrationRequest -Confirm:$false}
	Progress 70 "Disabling mail public folders on Exchange 2013..."
	$mpf=Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-MailPublicFolder}
	$mpf=@($mpf|?{$_.EntryId -ne $null})
	$mpf|Invoke-Command -Session $Global:exch13Session -ScriptBlock {Disable-MailPublicFolder -Confirm:$false}
	Progress 80 "Removing public folders on Exchange 2013..."
	$mpf=@(Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-Mailbox -PublicFolder})
	if($mpf.count -gt 0){
		Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-PublicFolder -GetChildren \ |Remove-PublicFolder -Recurse -Confirm:$false}
	}
	Progress 90 "Removing public folder mailboxes..."
	$mpf=$mpf|?{$_.IsRootPublicFolderMailbox -ne $true}
	if($mpf -ne $null){
		$mpf|Invoke-Command -Session $Global:exch13Session -ScriptBlock {Remove-Mailbox -PublicFolder -Confirm:$false}
	}
	Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-Mailbox -PublicFolder|Remove-Mailbox -PublicFolder -Confirm:$false}
	Progress 100 "Done."
	if($Global:migrationStep -eq 2){$Global:migrationStep=3;$Global:currentDisplay="generateTabPage"}
	SetMigrationPageAvailablity
}

function generateButtonClick{
	Progress 8 "Preparing public folders for size mapping export..."
	$pfExport=New-Object System.Collections.ArrayList
	$skip=@("\NON_IPM_SUBTREE\OFFLINE ADDRESS BOOK","\NON_IPM_SUBTREE\SCHEDULE+ FREE BUSY")
	Progress 16 "Getting IPM_SUBTREE folders..."
	$pfs=@(Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolder \ -Recurse -ResultSize unlimited})
	Progress 24 "Getting NON_IPM_SUBTREE folders..."
	$pfs+=@(Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolder \non_ipm_subtree -Recurse -ResultSize unlimited})
	Progress 32 "Adding missing folders to size map..."
	$add=@("\","\NON_IPM_SUBTREE","\NON_IPM_SUBTREE\EFORMS REGISTRY")
	$add|%{
		$folder=New-Object PSObject -Property @{FolderName=$_; FolderSize=0}
		$pfExport.Add($folder)|Out-Null
	}
	Progress 40 "Getting public folder statistics..."

$pfd=@(Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolderDatabase})
$pfss=@()
$pfd|%{
	Invoke-Expression "`$pfss+=@(Invoke-Command -Session `$Global:exchLegacySession -ScriptBlock {Get-PublicFolderStatistics -ResultSize unlimited -Server '$($_.Server)'})"
}
$pfss=$pfss|sort FolderPath -Unique


	Progress 48 "Parsing public folder paths\sizes..."
	foreach($p in $pfss){
		$pf=$pfs|?{$_.identity -eq $p.identity}
		if($skip -notcontains $pf.parentpath){
			if($pf.parentpath -ne "\"){
				$path="\IPM_SUBTREE$($pf.parentpath)\$($pf.name)"
			}else{
				$path="\IPM_SUBTREE\$($pf.name)"
			}
			$size=$p.TotalItemSize.Value.ToBytes()
			$folder=New-Object PSObject -Property @{FolderName=$path; FolderSize=$size}
			$pfExport.Add($folder)|Out-Null
		}
	}
	Progress 56 "Exporting file $($Global:mappingFolder)pfmt_size_map.csv..."
	$pfExport|sort FolderName|Export-CSV -Path "$($Global:mappingFolder)pfmt_size_map.csv" -Force -NoTypeInformation -Encoding "Unicode"
	Progress 64 "Prparing data for mailbox mapping..."
	$pfImport=New-Object System.Collections.ArrayList
	Import-Csv "$($Global:mappingFolder)pfmt_size_map.csv"|%{
		$folder=New-Object PSObject -Property @{FolderName=$_.foldername; FolderSize=$_.foldersize; Mailbox=""}
		$pfImport.Add($folder)|Out-Null
	}
	Progress 72 "Assigning default mailbox mapping based on size..."
	$mxsize=([int]$maxMxSizeTextBox.Text)*1048576
	if($pfImport|?{([int]$_.foldersize) -ge $mxsize}){
#########Do something pop up
		return
	}
	$mxs=@(0)
	$pfImport|%{
		for($i=0;$i -lt $mxs.count;$i++){
			if($mxs[$i]+$_.foldersize -le $mxsize){
				$mxs[$i]+=$_.foldersize
				$_.mailbox="Mailbox${i}"
				break
			}
			if($i+1 -eq $mxs.count){
				$mxs+=(0)
				$i++
				$mxs[$i]+=$_.foldersize
				$_.mailbox="Mailbox${i}"
			}
		}
	}
	Progress 80 "Parsing mailbox mapping data..."
	$mapExport=New-Object System.Collections.ArrayList
	$pfImport|%{
		$folder=New-Object PSObject -Property @{FolderPath=$_.foldername; TargetMailbox=$_.mailbox}
		$mapExport.Add($folder)|Out-Null
	}
	Progress 88 "Exporting file $($Global:mappingFolder)pfmt_mailbox_map.csv..."
	$mapExport|sort FolderPath|Export-CSV -Path "$($Global:mappingFolder)pfmt_mailbox_map.csv" -Force -NoTypeInformation -Encoding "Unicode"
	Progress 100 "Done."
	if($Global:migrationStep -eq 3){$Global:migrationStep=4}
	SetMigrationPageAvailablity
}

function GetCreateNodeTree{
	$Global:currentDisplay="createTreeView"
	Progress 10 "Clearing public folder mailbox tree nodes..."
	$createTreeView.Nodes.Clear()
	Progress 20 "Importing public folder mailbox mapping file..."
	$treeImport=Import-Csv "$($Global:mappingFolder)pfmt_mailbox_map.csv"
	Progress 30 "Creating context menu for public folder mailboxes..."
	$ContextMenuStrip=New-Object System.Windows.Forms.ContextMenuStrip
	$ContextMenuStrip.Items.Add("Rename").add_Click({ModifyPublicFolderMailbox $this $_ "rename"})
	$ContextMenuStrip.Items.Add("New Mailbox").add_Click({ModifyPublicFolderMailbox $this $_ "new"})
	$ContextMenuStrip.Items.Add("Delete Mailbox").add_Click({ModifyPublicFolderMailbox $this $_ "delete"})
	$ContextMenuStrip.Items.Add("Save Map File").add_Click({ModifyPublicFolderMailbox $this $_ "save"})
	Progress 40 "Creating public folder mailbox mapping tree structure..."
	$treeImport|Sort targetmailbox -Unique|%{
		$mx=$_.TargetMailbox
		$TreeNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
		$TreeNode.Tag=$mx
		$TreeNode.Name=$mx
		$TreeNode.Text="${mx} ()"
		$TreeNode.ImageIndex=6
		$TreeNode.SelectedImageIndex=6
		$TreeNode.ContextMenuStrip=$ContextMenuStrip
		$createTreeView.Nodes.Add($TreeNode)|Out-Null
		$treeImport|?{$_.TargetMailbox -eq $mx}|Sort folderpath|%{
			$path=$_.FolderPath.tostring().split("\")
			$cmd="`$createTreeView.Nodes[`$mx]"
			foreach($node in $path){
				if($node -ne "" -and ([array]::indexof($path,$node)+1) -ne $path.count){
					Invoke-Expression "`$needed=${cmd}.Nodes['${node}']"
					if(!($needed)){
						Invoke-Expression "`$addto=${cmd}"
						$tag=$cmd.replace("`$createTreeView.Nodes[`$mx]","\").replace("Nodes['","").replace("']","\").replace("']","").replace(".","")+$node
						$TreeNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
						$TreeNode.Tag=$tag
						$TreeNode.Name=$node
						$TreeNode.Text=$node
						$TreeNode.ImageIndex=5
						$TreeNode.SelectedImageIndex=5
						$TreeNode.ForeColor = [System.Drawing.Color]::FromArgb(255,128,128,128)
						$addto.Nodes.Add($TreeNode)|Out-Null
					}
					$cmd+=".Nodes['${node}']"
				}
			}
			Invoke-Expression "`$addto=${cmd}"
			$tag=$path -join "\"
			$node=$path[$path.count-1]
			if($node -eq ""){$node="IPM_SUBTREE"}
			$TreeNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
			$TreeNode.Tag=$tag
			$TreeNode.Name=$node
			$TreeNode.Text=$node
			$TreeNode.ImageIndex=0
			$TreeNode.SelectedImageIndex=0
			$addto.Nodes.Add($TreeNode)|Out-Null
		}
	}
	Progress 80 "Adding saved public folder mailboxes..."
	foreach($sm in $Global:saveMailboxes){
		$TreeNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
		$TreeNode.Tag=$sm
		$TreeNode.Name=$sm
		$TreeNode.Text=$sm
		$TreeNode.ImageIndex=6
		$TreeNode.SelectedImageIndex=6
		$createTreeView.Nodes.Add($TreeNode)|Out-Null
	}
	Progress 90 "Set display sizes for mailboxes..."
	SetPublicFolderMailboxDisplaySize
	Progress 100 "Done."
	GetMailboxDatabaseAssignment
}

function SetPublicFolderMailboxDisplaySize{
	$foldersizes=Import-Csv "$($Global:mappingFolder)pfmt_size_map.csv"
	foreach($mx in $createTreeView.Nodes){
		$Global:mxNodes=@()
		$size=0
		GetRecursiveMxNodes $mx
		$Global:mxNodes|?{$_.ImageIndex -eq 0}|%{
			$node=$_.Tag
			$size+=([int]($foldersizes|?{$_.FolderName -eq $node}).FolderSize)
		}
		switch($true){
			([int]($size/1073741824) -gt 0){$size=("{0:N1}" -f ($size/1073741824))+" GB";break}
			([int]($size/1048576) -gt 0){$size=("{0:N1}" -f ($size/1048576))+" MB";break}
			([int]($size/1024) -gt 0){$size=("{0:N1}" -f ($size/1024))+" KB";break}
			default{$size="${size} bytes"}
		}
		$mx.Text="$($mx.Name) (${size})"
	}
}

function ModifyPublicFolderMailbox($source,$event,$action){
	Progress 10 "Setting up for public folder mailbox modification..."
	$source=$source.Owner.SourceControl.SelectedNode
	$Global:mxSource=$source.Name
	$Global:mxAction=$action
	$Global:mxReturn=$null
	$cpath=$Global:curpath
	Progress 20 "Initiating popup for modification..."
	."${cpath}\Bin\modifyMxForm.ps1"
	Progress 30 "Checking popup results..."
	if($Global:mxReturn -eq $null){Progress 90 "Canceling modification process...";Progress 100 "Done.";return}
	if($action -eq "rename" -or $action -eq "new"){
		Progress 40 "Checking for mailbox name '$($Global:mxReturn)' for rename or new modification..."
		foreach($mx in $createTreeView.Nodes){
			if($mx.Name -eq $Global:mxReturn){
				PopUp "`r`nPublic folder mailbox name already exists.`r`nNo changes have been made."
				Progress 100 "Done."
				return
			}
		}
	}
	Progress 50 "Checking for modification action on mailbox '$($Global:mxReturn)'..."
	switch($action){
		"rename"{
			Progress 70 "Renaming public folder mailbox '$($Global:mxReturn)'..."
			$source.Text=$Global:mxReturn
			$source.Name=$Global:mxReturn
			$source.Tag=$Global:mxReturn
		}
		"new"{
			Progress 70 "Creating new public folder mailbox '$($Global:mxReturn)'..."
			$ContextMenuStrip=New-Object System.Windows.Forms.ContextMenuStrip
			$ContextMenuStrip.Items.Add("Rename").add_Click({ModifyPublicFolderMailbox $this $_ "rename"})
			$ContextMenuStrip.Items.Add("New Mailbox").add_Click({ModifyPublicFolderMailbox $this $_ "new"})
			$ContextMenuStrip.Items.Add("Delete Mailbox").add_Click({ModifyPublicFolderMailbox $this $_ "delete"})
			$ContextMenuStrip.Items.Add("Save Map File").add_Click({ModifyPublicFolderMailbox $this $_ "save"})
			$TreeNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
			$TreeNode.Tag=$Global:mxReturn
			$TreeNode.Name=$Global:mxReturn
			$TreeNode.Text="$($Global:mxReturn) ()"
			$TreeNode.ImageIndex=6
			$TreeNode.SelectedImageIndex=6
			$TreeNode.ContextMenuStrip=$ContextMenuStrip
			$createTreeView.Nodes.Add($TreeNode)|Out-Null
		}
		"delete"{
			Progress 50 "Verifying delete action..."
			if($Global:mxReturn -eq "delete"){
				Progress 60 "Checking for public folders assigned to mailbox '$($Global:mxReturn)'..."
				if($source.Nodes.count -gt 0){
					PopUp "`r`nThis public folder mailbox is not empty.`r`nPlease remove all public folders first."
					Progress 100 "Done."
					return
				}
				Progress 70 "Removing public folder mailbox '$($Global:mxReturn)'..."
				$createTreeView.Nodes.Remove($source)
			}
		}
		"save"{
			Progress 50 "Verifying save action..."
			if($Global:mxReturn -eq "save"){
				Progress 70 "Saving public folder mailbox mapping file..."
				UpdatePublicFolderMappingFile
			}
		}
	}
	Progress 90 "Set display sizes for mailboxes..."
	SetPublicFolderMailboxDisplaySize
	Progress 100 "Done."
}

function MovePublicFolderMailboxAssignment($node){
	Progress 10 "Checking for target and source public folders for folder move..."
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = $node.X
	$System_Drawing_Point.Y = $node.Y
	$targetPoint=$createTreeView.PointToClient($System_Drawing_Point)
	$targetpf=$createTreeView.GetNodeAt($targetPoint)
	$sourcepf=$node.Data.GetData([System.Windows.Forms.TreeNode])
	Progress 20 "Verifying source and target are valid for the move..."
	if(($sourcepf -ne $null -and $targetpf -ne $null) -and ($sourcepf.ImageIndex -ne 5) -and ($sourcepf.ImageIndex -ne 6)){
		Progress 30 "Getting the target mailbox for the folder move..."
		$targetmx=$targetpf
		while($targetmx.Parent -ne $null){$targetmx=$targetmx.Parent}
		$sourcemx=$sourcepf
		while($sourcemx.Parent -ne $null){$sourcemx=$sourcemx.Parent}
		Progress 40 "Verifying the folder is moving to a new mailbox..."
		if($sourcemx -ne $targetmx){
			$Global:folderMove=@($sourcepf.tag,$sourcemx.text,$targetmx.text)
			$cpath=$Global:curpath
			Progress 50 "Initiating popup for folder only or subfolder move..."
			."${cpath}\Bin\movePfForm.ps1"
			Progress 60 "Checking for desired move action..."
			if($Global:folderMove -eq "folderOnly" -or $Global:folderMove -eq "subfolders"){
				Progress 70 "Creating necessary folder structure for move..."
				$spath=$sourcepf.tag.split("\")
				$cmd=$targetmx
				foreach($node in $spath){
					if($node -ne "" -and ([array]::indexof($spath,$node)+1) -ne $spath.count){
						$needed=$cmd.Nodes[$node]
						if(!($needed)){
							$addto=$cmd
							$tag=$sourcepf.tag.Substring(0,$sourcepf.tag.indexof($node)+$_.length)+$node
							$TreeNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
							$TreeNode.Tag=$tag
							$TreeNode.Name=$node
							$TreeNode.Text=$node
							$TreeNode.ImageIndex=5
							$TreeNode.SelectedImageIndex=5
							$TreeNode.ForeColor = [System.Drawing.Color]::FromArgb(255,128,128,128)
							$addto.Nodes.Add($TreeNode)|Out-Null
						}
						$cmd=$cmd.Nodes[$node]
					}
				}
			}else{
				Progress 90 "User canceled move action..."
			}
			Progress 80 "Moving folder to new mailbox assignment..."
			if($Global:folderMove -eq "folderOnly" -and $sourcepf.GetNodeCount($false) -gt 0){
				$folder=$sourcepf.Text
				$fullpath=$sourcepf.FullPath
				$addback=$createTreeView.Nodes.Find($folder, $true)
				$addback=$addback|?{$_.FullPath -eq $fullpath}
				$addback=$addback.Parent
				$sourcepf.Nodes.Remove($sourcepf)
				$cmd.Nodes.Add($sourcepf)
				$TreeNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
				$TreeNode.Tag=$fullpath
				$TreeNode.Name=$folder
				$TreeNode.Text=$folder
				$TreeNode.ImageIndex=5
				$TreeNode.SelectedImageIndex=5
				$TreeNode.ForeColor = [System.Drawing.Color]::FromArgb(255,128,128,128)
				$addback.Nodes.Add($TreeNode)|Out-Null
				Progress 90 "Pushing subfolders back to original mailbox..."
				while($sourcepf.GetNodeCount($false) -gt 0){
					$move=$sourcepf.FirstNode
					$sourcepf.Nodes.Remove($move)
					$TreeNode.Nodes.Add($move)
				}
			}elseif($Global:folderMove -eq "folderOnly" -or $Global:folderMove -eq "subfolders"){
				$sourcepf.Nodes.Remove($sourcepf)
				$cmd.Nodes.Add($sourcepf)
			}
			Progress 95 "Cleaning up pulbic folder mailbox structures..."
			CheckPFMailboxDuplicates
			CleanUpEmptyFolders
		}
	}else{
		Progress 90 "Canceling invalid move..."
	}
	Progress 98 "Set display sizes for mailboxes..."
	SetPublicFolderMailboxDisplaySize
	Progress 100 "Done."
}

function CheckPFMailboxDuplicates{
	Progress 50 "Cleaning up public folder mailbox duplicated nodes..."
	foreach($mx in $createTreeView.Nodes){
		$Global:mxNodes=@()
		GetRecursiveMxNodes $mx
		$Global:mxNodes|%{
			$node=$_
			$cnt=0
			$Global:mxNodes|%{
				$fullpath=$_.FullPath
				$check=$createTreeView.Nodes.Find($_.Text, $true)
				$check=$check|?{$_.FullPath -eq $fullpath}
				if($check.count -gt 1){
					while($check[0].GetNodeCount($false) -gt 0){
						$move=$check[0].FirstNode
						$check[0].Nodes.Remove($move)
						$check[1].Nodes.Add($move)
					}
					$check[0].Parent.Nodes.Remove($check[0])
				}
			}
		}
	}
	Progress 100 "Done."
}

function CleanUpEmptyFolders{
	Progress 50 "Cleaning up empty public folders with different mailbox assignments..."
	foreach($mx in $createTreeView.Nodes){
		$Global:mxNodes=@()
		GetRecursiveMxNodes $mx
		$Global:mxNodes|?{$_.ImageIndex -eq 5}|sort tag -descending|%{
			if($_.GetNodeCount($true) -eq 0){
				$_.Parent.Nodes.Remove($_)
			}
		}
	}
	Progress 100 "Done."
}

function UpdatePublicFolderMappingFile{
	Progress 10 "Importing public folder mailbox mapping files for update..."
	$treeImport=Import-Csv "$($Global:mappingFolder)pfmt_mailbox_map.csv"
	Progress 60 "Checking for duplicated mailbox names and setting assignments..."
	foreach($mx in $createTreeView.Nodes){
		if(($createTreeView.Nodes|?{$_.Text -eq $mx.Name}).count -gt 1){
			PopUp "`r`nThere are duplicated mailbox names.`r`nPlease give all mailboxes unique names."
			return
		}
		$Global:mxNodes=@()
		GetRecursiveMxNodes $mx
		$Global:mxNodes|?{$_.ImageIndex -eq 0}|%{
			$path=$_.Tag
			($treeImport|?{$_.FolderPath -eq $path}).TargetMailbox=$mx.Name
		}
	}
	Progress 90 "Exporting new public folder mailbox mapping file..."
	$treeImport|sort FolderPath|Export-CSV -Path "$($Global:mappingFolder)pfmt_mailbox_map.csv" -Force -NoTypeInformation -Encoding "Unicode"
	Progress 100 "Done."
}

function GetRecursiveMxNodes($mx){
	foreach($folder in $mx.Nodes){
		$Global:mxNodes+=@($folder)
		GetRecursiveMxNodes $folder
	}
}

function createButtonClick{
	UpdatePublicFolderMappingFile
	if($Global:migrationStep -eq 3){$Global:migrationStep=4}
	SetMigrationPageAvailablity
}

function GetMailboxDatabaseAssignment{
	Progress 10 "Importing public folder mailbox mapping info..."
	$treeImport=Import-Csv "$($Global:mappingFolder)pfmt_mailbox_map.csv"
	Progress 20 "Getting Exchange 2013 mailbox databases..."
	$mxdb=@(Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-MailboxDatabase})
	Progress 40 "Removing previous mailbox to database assignment display..."
	$assignGroupPanel.Controls|?{$_.Name -like "isRadioButton*"}|%{$assignGroupPanel.Controls.Remove($_)}
	$assignGroupPanel.Controls|?{$_.Name -like "dbComboBox*"}|%{$assignGroupPanel.Controls.Remove($_)}
	$assignGroupPanel.Controls|?{$_.Name -like "mxTextBox*"}|%{$assignGroupPanel.Controls.Remove($_)}
	Progress 50 "Configuring mailbox to database assignment display..."
	$i=0
	$s=62
	$treeImport|Sort targetmailbox -Unique|%{
		$y=$s+(30*$i)
		$isRadioButton = New-Object System.Windows.Forms.RadioButton
		$dbComboBox = New-Object System.Windows.Forms.ComboBox
		$mxTextBox = New-Object System.Windows.Forms.TextBox

		$System_Drawing_Point = New-Object System.Drawing.Point
		$System_Drawing_Point.X = 410
		$System_Drawing_Point.Y = $y
		$isRadioButton.Location = $System_Drawing_Point
		$isRadioButton.Name = "isRadioButton${i}"
		$isRadioButton.Tag=$_.TargetMailbox
		$System_Drawing_Size = New-Object System.Drawing.Size
		$System_Drawing_Size.Height = 24
		$System_Drawing_Size.Width = 59
		$isRadioButton.Size = $System_Drawing_Size
		$isRadioButton.TextAlign = 1
		$isRadioButton.UseVisualStyleBackColor = $True
		$assignGroupPanel.Controls.Add($isRadioButton)

		$dbComboBox.FormattingEnabled = $True
		$System_Drawing_Point = New-Object System.Drawing.Point
		$System_Drawing_Point.X = 213
		$System_Drawing_Point.Y = $y
		$dbComboBox.Location = $System_Drawing_Point
		$dbComboBox.Name = "dbComboBox${i}"
		$dbComboBox.Tag=$_.TargetMailbox
		$System_Drawing_Size = New-Object System.Drawing.Size
		$System_Drawing_Size.Height = 21
		$System_Drawing_Size.Width = 150
		$dbComboBox.Size = $System_Drawing_Size
		$assignGroupPanel.Controls.Add($dbComboBox)

		$mxTextBox.BackColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
		$System_Drawing_Point = New-Object System.Drawing.Point
		$System_Drawing_Point.X = 57
		$System_Drawing_Point.Y = $y
		$mxTextBox.Location = $System_Drawing_Point
		$mxTextBox.Name = "mxTextBox${i}"
		$mxTextBox.Tag=$_.TargetMailbox
		$mxTextBox.Text=$_.TargetMailbox
		$mxTextBox.ReadOnly = $True
		$System_Drawing_Size = New-Object System.Drawing.Size
		$System_Drawing_Size.Height = 20
		$System_Drawing_Size.Width = 150
		$mxTextBox.Size = $System_Drawing_Size
		$assignGroupPanel.Controls.Add($mxTextBox)
		
		$mxdb|%{
			$dbComboBox.Items.Add($_.Name)|Out-Null
		}
		$dbComboBox.SelectedIndex = 0
		$i++
	}
	Progress 90 "Setting default 'Is Root' assignment..."
	($assignGroupPanel.Controls|?{$_.Name -eq "isRadioButton0"}).Checked=$true
	Progress 100 "Done."
}

function migrateButtonClick{
	$Global:migResponse="migrate"
	$cpath=$Global:curpath
	."${cpath}\Bin\migForm.ps1"
	if($Global:migResponse -ne "OK"){return}
	$Global:rootMx=($assignGroupPanel.Controls|?{$_.Name -like "isRadioButton*" -and $_.Checked -eq $true}).Tag
	SetConfig "rootMx" $Global:rootMx
	if($Global:migrationStep -eq 4){$Global:migrationStep=5}
	SetMigrationPageAvailablity
}

function GetMigrationProgress{
	$Global:currentDisplay="progressTabPage"
	if($Global:migrationStep -eq 5){
		SetMigrationProgressBars 1 10 "Checking for remaining public folder mailboxes..."
		$mpf=@(Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-Mailbox -PublicFolder})
		if($mpf.count -gt 0){
			Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-PublicFolder -GetChildren \ |Remove-PublicFolder -Recurse -Confirm:$false}
		}
#		Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-PublicFolder -GetChildren \ |Remove-PublicFolder -Recurse -Confirm:$false}
#		$mpf=Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-Mailbox -PublicFolder}
		SetMigrationProgressBars 1 20 "Removing remaining public folders mailboxes..."
		$mpf=$mpf|?{$_.IsRootPublicFolderMailbox -ne $true}
		$mpf|Invoke-Command -Session $Global:exch13Session -ScriptBlock {Remove-Mailbox -PublicFolder -Confirm:$false}
		Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-Mailbox -PublicFolder|Remove-Mailbox -PublicFolder -Confirm:$false}
		SetMigrationProgressBars 1 30 "Removing any previous migrations..."

		$treeImport=Import-Csv "$($Global:mappingFolder)pfmt_mailbox_map.csv"
		$treeImport=$treeImport|Sort targetmailbox -Unique
		SetMigrationProgressBars 1 40 "Creating root public folder mailbox '$($Global:rootMx)'..."
		Invoke-Expression "Invoke-Command -Session `$Global:exch13Session -ScriptBlock {New-Mailbox -PublicFolder '$($Global:rootMx)' -HoldForMigration}"
		$step=40/$treeImport.count
		$i=1
		$treeImport|?{$_.TargetMailbox -ne $Global:rootMx}|%{
			$val=($step*$i)+40
			$i++
			SetMigrationProgressBars 1 $val "Creating public folder mailbox '$($_.TargetMailbox)'..."
			Invoke-Expression "Invoke-Command -Session `$Global:exch13Session -ScriptBlock {New-Mailbox -PublicFolder '$($_.TargetMailbox)'}"
		}
		SetMigrationProgressBars 1 90 "Verifying public folder mailboxes..."
		$mxs=@()
		Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-Mailbox -PublicFolder}|%{
			$mxs+=@($_.Name)
		}
		$check=$true
		$treeImport|%{
			if($mxs -notcontains $_.TargetMailbox){
				$check=$false
			}
		}
		if(!$check){
			SetConfig "migrationStep" 4
			PopUp "`r`nCould not vailidate the creation of the neccessary public folder mailboxes." -Fatal
			return
		}
		if($Global:migrationStep -eq 5){$Global:migrationStep=6}
		SetMigrationPageAvailablity
	}elseif($Global:migrationStep -eq 6){
		SetMigrationProgressBars 1 100 "Done."
		SetMigrationProgressBars 2 10 "Preparing for the  public folder migration request..."
		$map="$($Global:mappingFolder)pfmt_mailbox_map.csv"
		$pfdb=@(Invoke-Command -Session $Global:exchLegacySession -ScriptBlock {Get-PublicFolderDatabase|Get-PublicFolderDatabase -Status})
		$pfdb=@($pfdb|?{$_.Mounted -eq $true})
		if($pfdb.count -lt 1){
			SetConfig "migrationStep" 4
			PopUp "`r`nNo public folder databases are mounted." -Fatal
			return	
		}
		SetMigrationProgressBars 2 20 "Creating the public folder migration request..."
		New-PublicFolderMigrationRequest -Name "PFMT_Migration" -SourceDatabase $pfdb[0].Name -CSVData (Get-Content $map -Encoding Byte)
		if($Global:migrationStep -eq 6){$Global:migrationStep=7}
		SetMigrationPageAvailablity
	}elseif($Global:migrationStep -eq 7){
		$pfmr=@(Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-PublicFolderMigrationRequest})
		if($pfmr.count -lt 1){
			SetConfig "migrationStep" 4
			PopUp "`r`nPublic folder migration request is missing." -Fatal
			return	
		}
		$migTimer=New-Object System.Windows.Forms.Timer
		$migTimer.Interval=100
		$migTimer.add_Tick({
			$this.Stop()
			GetMigProgressProgressBarValue $this
			if($migProgressProgressBar.Value -ne 100){
				$this.Start()
			}else{
				if($Global:migrationStep -eq 7){$Global:migrationStep=8}
				SetMigrationPageAvailablity
			}
		})
		$migTimer.Start()
		$forceButton.Enabled = $true
	}
}

function GetMigProgressProgressBarValue{
	$pfmr=Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-PublicFolderMigrationRequestStatistics "\PFMT_Migration"}
	$stat=$pfmr.StatusDetail.tostring()
	$progress=20+(($pfmr.PercentComplete*80)/95)
	SetMigrationProgressBars 2 $progress "Migration in progress with status '${stat}'..."
}

function SetMigrationProgressBars($bar,$value,$msg){
	$migPrepStepLabel.Text=""
	$migProgressStepLabel.Text=""
	$migPrepProgressBar.Value=0
	$migProgressProgressBar.Value=0
	$migPrepProgressBar.ForeColor = [System.Drawing.Color]::FromArgb(255,9,36,107)
	$migProgressProgressBar.ForeColor = [System.Drawing.Color]::FromArgb(255,9,36,107)
	if($bar -eq 1){
		$migPrepStepLabel.Text=$msg
		$migPrepProgressBar.Value=$value
	}elseif($bar -eq 2){
		$migPrepStepLabel.Text="Done."
		$migPrepProgressBar.Value=100
		$migPrepProgressBar.ForeColor = [System.Drawing.Color]::FromArgb(255,6,176,37)
		$migProgressStepLabel.Text=$msg
		$migProgressProgressBar.Value=$value
		if($value -eq 100){$migProgressProgressBar.ForeColor = [System.Drawing.Color]::FromArgb(255,6,176,37)}
	}
	if($Global:logfile -ne "" -and $msg -ne $null){AddLog $msg}
}

function GetMailboxesForFinalizeTest{
	Progress 40 "Getting list of mailboxes for testing..."
	$mxs=@(Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-Mailbox -ResultSize unlimited})
	$mxs=@($mxs|?{$_.ExchangeVersion -like '*15*'})
	if($mxs.count -eq 0){
			PopUp "`r`nThere are no 2013 mailboxes to test with during the final process.`r`nPlease move or create a mailbox and restart the Tool." -Fatal
			return
	}
	$mxs|%{
		$ListViewItem = New-Object System.Windows.Forms.ListViewItem
		$ListViewItem.Name = $_.Alias
		$ListViewItem.Text = $_.Alias
		$finalizeListView.Items.Add($ListViewItem)|Out-Null
	}
	Progress 100 "Done."
}

function finalizeButtonClick{
	if($Global:migrationStep -eq 8){
		$Global:testMX=$finalizeListView.SelectedItems[0].Text
		$Global:migResponse="finalize"
		$cpath=$Global:curpath
		."${cpath}\Bin\migForm.ps1"
		if($Global:migResponse -ne "OK"){return}
		$finalizeStepLabel.Text = "The migration of the public folder data has completed."
		SetFinalizeProgressBars 10 "Locking public folders..."
		Invoke-Command -Session $Global:exch13Session -ScriptBlock {Set-OrganizationConfig -PublicFoldersLockedForMigration:$true}
		SetFinalizeProgressBars 20 "Setting migration request to complete..."
		Invoke-Command -Session $Global:exch13Session -ScriptBlock {Set-PublicFolderMigrationRequest "\PFMT_Migration" -PreventCompletion:$false}
		SetFinalizeProgressBars 30 "Resuming the migration..."
		Invoke-Command -Session $Global:exch13Session -ScriptBlock {Resume-PublicFolderMigrationRequest "\PFMT_Migration"}
		$migTimer=New-Object System.Windows.Forms.Timer
		$migTimer.Interval=100
		$migTimer.add_Tick({
			$this.Stop()
			GetFinalizeProgressBarValue
			if($finalizeProgressBar.Value -ne 60){
				$this.Start()
			}else{
				if($Global:migrationStep -eq 8){$Global:migrationStep=9}
				SetMigrationPageAvailablity
			}
		})
		$migTimer.Start()
		$forceButton.Enabled = $true
	}elseif($Global:migrationStep -eq 9){
		SetFinalizeProgressBars 70 "Testing public folder mailbox availability..."
		$pfm=@(Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-Mailbox -PublicFolder})
		$pfm=$pfm[0].Name
		Invoke-Expression "Invoke-Command -Session `$Global:exch13Session -ScriptBlock {Set-Mailbox -Identity '$($Global:testMX)' -DefaultPublicFolderMailbox '${pfm}'}"
		$gmx=Invoke-Expression "Invoke-Command -Session `$Global:exch13Session -ScriptBlock {Get-Mailbox -Identity '$($Global:testMX)'}"
		if($gmx.DefaultPublicFolderMailbox -notlike "*${pfm}"){
			PopUp "`r`nFailed test to set mailbox to user the new public folder structure.`r`nTry again or restart the migration." -Fatal
			return
		}else{
			Invoke-Expression "Invoke-Command -Session `$Global:exch13Session -ScriptBlock {Set-Mailbox -Identity '$($Global:testMX)' -DefaultPublicFolderMailbox `$null}"
		}
		SetFinalizeProgressBars 80 "Setting public folder mailboxes to serve the hierarchy..."
		Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-Mailbox -PublicFolder | Set-Mailbox -PublicFolder -IsExcludedFromServingHierarchy $false}
		SetFinalizeProgressBars 90 "Setting the migration as successfully completed..."
		Invoke-Command -Session $Global:exch13Session -ScriptBlock {Set-OrganizationConfig -PublicFolderMigrationComplete:$true}
		SetFinalizeProgressBars 100 "Done."
		if($Global:migrationStep -eq 9){$Global:migrationStep=10}
		SetMigrationPageAvailablity
	}
}

function GetFinalizeProgressBarValue{
	$pfmr=Invoke-Command -Session $Global:exch13Session -ScriptBlock {Get-PublicFolderMigrationRequestStatistics "\PFMT_Migration"}
	$stat=$pfmr.StatusDetail.tostring()
	if(!($pfmr) -or $pfmr.PercentComplete -lt 95){
		SetFinalizeProgressBars $finalizeProgressBar.Value "Issues getting the public folder request statistics..."
		$finalizeProgressBar.ForeColor = [System.Drawing.Color]::FromArgb(255,255,0,0)
		return
	}
	$progress=30+(($pfmr.PercentComplete-95)*6)
		SetFinalizeProgressBars $progress "Completing migration in progress with status '${stat}'..."
}

function SetFinalizeProgressBars($val,$msg){
	$finalizeProgressBar.ForeColor = [System.Drawing.Color]::FromArgb(255,9,36,107)
	$finalizeProgressBar.Value=$val
	$finalizeStepLabel.Text=$msg
	if($val -eq 100){$finalizeProgressBar.ForeColor = [System.Drawing.Color]::FromArgb(255,6,176,37)}
}

function ForceCompleteMigration{
	Progress 10 "Confirming force migration..."
	$Global:migResponse="force"
	$cpath=$Global:curpath
	."${cpath}\Bin\migForm.ps1"
	if($Global:migResponse -ne "OK"){Progress 100 "Done.";return}
	$MRSServer=@()
	$MRSServer=(Get-PublicFolderMigrationRequestStatistics "\PFMT_Migration" -IncludeReport).Report.Connectivity
	if($MRSServer[0].ServerName -eq $null -or $svr -eq ""){
		PopUp "`r`nUnable to get the MRS server."
		return
	}
	$svr=$MRSServer[0].ServerName
	(Get-WmiObject win32_service -ComputerName $svr -Filter "Name='MSExchangeMailboxReplication'").InvokeMethod("StopService",$null)
	while($state -ne "Stopped"){
		Progress 30 "Stopping the 'MSExchangeMailboxReplication' service on server '${svr}'..."
		$state=(Get-WmiObject Win32_Service -ComputerName $svr -Filter "Name='MSExchangeMailboxReplication'").State
	}
	(Get-WmiObject win32_service -ComputerName $svr -Filter "Name='MSExchangeMailboxReplication'").InvokeMethod("StartService",$null)
	while($state -ne "Running"){
		Progress 50 "Starting the 'MSExchangeMailboxReplication' service on server '${svr}'..."
		$state=(Get-WmiObject Win32_Service -ComputerName $svr -Filter "Name='MSExchangeMailboxReplication'").State
	}
	Progress 70 "Suspending the public folder migration request..."
	Invoke-Command -Session $Global:exch13Session -ScriptBlock {Suspend-PublicFolderMigrationRequest "\PFMT_Migration" -Confirm:$false}
	Progress 90 "Resuming the public folder migration request..."
	Invoke-Command -Session $Global:exch13Session -ScriptBlock {Resume-PublicFolderMigrationRequest "\PFMT_Migration"}
	Progress 100 "Done."
}

function CompletedMigration{

}

function GenerateForm {

	#region Import Assemblies
	[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
	[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
	[System.Windows.Forms.Application]::EnableVisualStyles()
	#endregion Import Assemblies

	#region Declair Main Objects
	$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
	
	$pfmtForm = New-Object System.Windows.Forms.Form
	$pfmtIcon = New-Object system.drawing.icon ("$($Global:curpath)\Bin\pfmt.ico")
	$displayPanel = New-Object System.Windows.Forms.Panel
	$displayMessageTextBox = New-Object System.Windows.Forms.TextBox
	$mainSplitter = New-Object System.Windows.Forms.Splitter
	$actionPanel = New-Object System.Windows.Forms.Panel
	$actionTreeView = New-Object System.Windows.Forms.TreeView
	$statusPanel = New-Object System.Windows.Forms.Panel
	$spacePanel = New-Object System.Windows.Forms.Panel
	$messagePanel = New-Object System.Windows.Forms.Panel
	$messageLabel = New-Object System.Windows.Forms.Label
	$progressPanel = New-Object System.Windows.Forms.Panel
	$progressBar = New-Object System.Windows.Forms.ProgressBar
	$toolBar = New-Object System.Windows.Forms.ToolBar
	
	$buttonList = New-Object System.Windows.Forms.ImageList
	$nodeList = New-Object System.Windows.Forms.ImageList
	$extraList = New-Object System.Windows.Forms.ImageList
	
	$scriptsButton = New-Object System.Windows.Forms.ToolBarButton
	$connectButton = New-Object System.Windows.Forms.ToolBarButton
	$helpButton = New-Object System.Windows.Forms.ToolBarButton
	$refreshButton = New-Object System.Windows.Forms.ToolBarButton
	
	$filterPanel = New-Object System.Windows.Forms.Panel
	$filterRightPanel = New-Object System.Windows.Forms.Panel
	$resutSizeLabel = New-Object System.Windows.Forms.Label
	$resultSizeTextBox = New-Object System.Windows.Forms.TextBox
	$filterLeftPanel = New-Object System.Windows.Forms.Panel
	$filterControlPanel = New-Object System.Windows.Forms.Panel
	$applyFilterButton = New-Object System.Windows.Forms.Button
	$valueTextBox = New-Object System.Windows.Forms.TextBox
	$comparisonComboBox = New-Object System.Windows.Forms.ComboBox
	$attributeComboBox = New-Object System.Windows.Forms.ComboBox
	$filterCheckBox = New-Object System.Windows.Forms.CheckBox
	
	$pubFolMigNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
	$migPubFolNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
	$verMigNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
	$rolBacMigNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
	$pubFolTooNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
	$pubfolNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
	$pubFolDatNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
	$pubFolMaiNode = New-Object System.Windows.Forms.TreeNode("Microsoft Exchange")
	#endregion Declair Main Objects

	#region Load Image Lists
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 27
	$System_Drawing_Size.Width = 27
	$buttonList.ImageSize = $System_Drawing_Size
	$imgdir=$Global:curpath
	$imgdir+="\Bin\resources\buttons"
	ls $imgdir|?{$_.name -like "*.png"}|sort name|%{
		$file=(get-item "${imgdir}\${_}")
		$img=[System.Drawing.Image]::Fromfile($file)
		$buttonList.Images.Add($img);
	}
	
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 18
	$System_Drawing_Size.Width = 18
	$nodeList.ImageSize = $System_Drawing_Size
	$imgdir=$Global:curpath
	$imgdir+="\Bin\resources\nodes"
	ls $imgdir|?{$_.name -like "*.png"}|sort name|%{
		$file=(get-item "${imgdir}\${_}")
		$img=[System.Drawing.Image]::Fromfile($file)
		$nodeList.Images.Add($img);
	}
	
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 18
	$System_Drawing_Size.Width = 18
	$extraList.ImageSize = $System_Drawing_Size
	$imgdir=$Global:curpath
	$imgdir+="\Bin\resources\extra"
	ls $imgdir|?{$_.name -like "*.png"}|sort name|%{
		$file=(get-item "${imgdir}\${_}")
		$img=[System.Drawing.Image]::Fromfile($file)
		$extraList.Images.Add($img);
	}
	#endregion Load Image Lists
	
	#region Set Main Object Properties
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 600
	$System_Drawing_Size.Width = 800
	$pfmtForm.ClientSize = $System_Drawing_Size
	$pfmtForm.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",8.5,0,3,0)
	$System_Drawing_Size.Height = 600
	$System_Drawing_Size.Width = 800
	$pfmtForm.MinimumSize = $System_Drawing_Size
	$pfmtForm.StartPosition = 1
	$pfmtForm.Icon = $pfmtIcon
	$pfmtForm.Name = "pfmtForm"
	$pfmtForm.Text = "Public Folder Migration Tool"

	$displayPanel.BorderStyle = 2
	$displayPanel.Dock = 5
	$displayPanel.Name = "dispayPanel"
	$displayPanel.TabIndex = 0
	$pfmtForm.Controls.Add($displayPanel)
	
	$displayMessageTextBox.BackColor = $pfmtForm.BackColor
	$displayMessageTextBox.BorderStyle = 0
	$displayMessageTextBox.Cursor = [System.Windows.Forms.Cursors]::Arrow
	$displayMessageTextBox.ReadOnly = $True
	$displayMessageTextBox.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",8.25,1,3,1)
	$displayMessageTextBox.Multiline = $True
	$displayMessageTextBox.Name = "displayMessageTextBox"
	$displayMessageTextBox.Dock = 5
	$displayMessageTextBox.TextAlign = "Center"
	$displayMessageTextBox.TabStop = $False
	$displayMessageTextBox.Text = "`r`nSet the location of the migration scripts to proceed."
	$displayPanel.Controls.Add($displayMessageTextBox)
		
	$mainSplitter.Name = "mainSplitter"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Width = 3
	$mainSplitter.Size = $System_Drawing_Size
	$mainSplitter.TabStop = $False
	$pfmtForm.Controls.Add($mainSplitter)


	$actionPanel.BorderStyle = 2
	$actionPanel.Dock = 3
	$actionPanel.Name = "actionPanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Width = 220
	$actionPanel.Size = $System_Drawing_Size
	$pfmtForm.Controls.Add($actionPanel)

	$actionTreeView.BorderStyle = 0
	$actionTreeView.Dock = 5
	$actionTreeView.Name = "actionTreeView"
	$actionTreeView.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",9,0,3,0)
	$actionTreeView.ShowLines = $False
	$actionTreeView.ImageList = $nodeList
	$actionTreeView.TabStop = $False
	$actionPanel.Controls.Add($actionTreeView)

	$statusPanel.Dock = 2
	$statusPanel.Name = "statusPanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 30
	$statusPanel.Size = $System_Drawing_Size
	$pfmtForm.Controls.Add($statusPanel)

	$spacePanel.BorderStyle = 2
	$spacePanel.Dock = 5
	$spacePanel.Name = "spacePanel"
	$statusPanel.Controls.Add($spacePanel)

	$messagePanel.BorderStyle = 2
	$messagePanel.Dock = 3
	$messagePanel.Name = "messagePanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Width = 340
	$messagePanel.Size = $System_Drawing_Size
	$statusPanel.Controls.Add($messagePanel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 10
	$System_Drawing_Point.Y = 0
	$messageLabel.Location = $System_Drawing_Point
	$messageLabel.Name = "messageLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 30
	$System_Drawing_Size.Width = 330
	$messageLabel.Size = $System_Drawing_Size
	$messageLabel.Text = "Done."
	$messageLabel.TextAlign = 16
	$messagePanel.Controls.Add($messageLabel)

	$progressPanel.BorderStyle = 2
	$progressPanel.Dock = 4
	$progressPanel.Name = "progressPanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Width = 340
	$progressPanel.Size = $System_Drawing_Size
	$statusPanel.Controls.Add($progressPanel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 0
	$System_Drawing_Point.Y = 0
	$progressBar.Location = $System_Drawing_Point
	$progressBar.Name = "progressBar"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 30
	$System_Drawing_Size.Width = 340
	$progressBar.Size = $System_Drawing_Size
	$progressPanel.Controls.Add($progressBar)
	#endregion Set Main Object Properties

	#region Set Filter Panel Properties
	$filterPanel.Dock = 1
	$filterPanel.Name = "filterPanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 30
	$filterPanel.Size = $System_Drawing_Size
	$pfmtForm.Controls.Add($filterPanel)
	
	$filterRightPanel.Dock = 4
	$filterRightPanel.Name = "filterRightPanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Width = 175
	$filterRightPanel.Size = $System_Drawing_Size
	$filterRightPanel.BorderStyle = 1
	$filterRightPanel.Enabled=$False
	$filterPanel.Controls.Add($filterRightPanel)
	
	$resutSizeLabel.Anchor = 9
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 7
	$System_Drawing_Point.Y = 4
	$resutSizeLabel.Location = $System_Drawing_Point
	$resutSizeLabel.Name = "resutSizeLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 75
	$resutSizeLabel.Size = $System_Drawing_Size
	$resutSizeLabel.Text = "Result Size:"
	$resutSizeLabel.TextAlign = 64
	$filterRightPanel.Controls.Add($resutSizeLabel)
	
	$resultSizeTextBox.Anchor = 9
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 88
	$System_Drawing_Point.Y = 5
	$resultSizeTextBox.Location = $System_Drawing_Point
	$resultSizeTextBox.Name = "resultSizeTextBox"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 20
	$System_Drawing_Size.Width = 75
	$resultSizeTextBox.Text = 1000
	$resultSizeTextBox.Size = $System_Drawing_Size
	$resultSizeTextBox.add_TextChanged({
		[int]$num=$null
		if(!([int32]::TryParse($resultSizeTextBox.Text,[ref]$num))){$resultSizeTextBox.Text="1000"}
	})
	$filterRightPanel.Controls.Add($resultSizeTextBox)

	$filterLeftPanel.Dock = 3
	$filterLeftPanel.Name = "filterLeftPanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Width = 673
	$filterLeftPanel.Size = $System_Drawing_Size
	$filterPanel.Controls.Add($filterLeftPanel)
	
	$filterControlPanel.Dock = 4
	$filterControlPanel.Name = "filterLeftPanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Width = 600
	$filterControlPanel.Size = $System_Drawing_Size
	$filterControlPanel.Enabled=$False
	$filterLeftPanel.Controls.Add($filterControlPanel)
	
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 480
	$System_Drawing_Point.Y = 5
	$applyFilterButton.Location = $System_Drawing_Point
	$applyFilterButton.Name = "applyFilterButton"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 50
	$applyFilterButton.Size = $System_Drawing_Size
	$applyFilterButton.Text = "Apply"
	$applyFilterButton.UseVisualStyleBackColor = $True
	$applyFilterButton.add_Click({ApplyFilter})
	$filterControlPanel.Controls.Add($applyFilterButton)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 335
	$System_Drawing_Point.Y = 5
	$valueTextBox.Location = $System_Drawing_Point
	$valueTextBox.Name = "valueTextBox"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 20
	$System_Drawing_Size.Width = 125
	$valueTextBox.Size = $System_Drawing_Size
	$valueTextBox.Text="*"
	$filterControlPanel.Controls.Add($valueTextBox)
	
	$comparisonComboBox.FormattingEnabled = $True
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 225
	$System_Drawing_Point.Y = 5
	$comparisonComboBox.Location = $System_Drawing_Point
	$comparisonComboBox.Name = "comparisonComboBox"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 21
	$System_Drawing_Size.Width = 100
	$comparisonComboBox.Size = $System_Drawing_Size
	$filterControlPanel.Controls.Add($comparisonComboBox)
	
	$comparisonComboBox.Items.Add("Equals")|Out-Null
	$comparisonComboBox.Items.Add("Does Not Equal")|Out-Null
	$comparisonComboBox.Items.Add("Is Like")|Out-Null
	$comparisonComboBox.Items.Add("Greater Than")|Out-Null
	$comparisonComboBox.Items.Add("Less Than")|Out-Null
	$comparisonComboBox.SelectedIndex = 2

	$attributeComboBox.FormattingEnabled = $True
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 20
	$System_Drawing_Point.Y = 5
	$attributeComboBox.Location = $System_Drawing_Point
	$attributeComboBox.Name = "attributeComboBox"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 21
	$System_Drawing_Size.Width = 200
	$attributeComboBox.Size = $System_Drawing_Size
	$filterControlPanel.Controls.Add($attributeComboBox)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 13
	$System_Drawing_Point.Y = 3
	$filterCheckBox.Location = $System_Drawing_Point
	$filterCheckBox.Name = "filterCheckBox"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 24
	$System_Drawing_Size.Width = 75
	$filterCheckBox.Size = $System_Drawing_Size
	$filterCheckBox.Text = "Filter"
	$filterCheckBox.UseVisualStyleBackColor = $True
	$filterCheckBox.Add_Click({SetFilterAvailability})
	$filterLeftPanel.Controls.Add($filterCheckBox)
	#endregion Set Filter Panel Properties
	
	#region Set Tool Bar Properties
	$toolBar.BorderStyle = 1
	$toolBar.Name = "toolBar"
	$toolBar.ShowToolTips = $True
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 263
	$toolBar.Size = $System_Drawing_Size
	$toolBar.ImageList = $buttonList
	$pfmtForm.Controls.Add($toolBar)
	
	$scriptsButton.Name = "scriptsButton"
	$scriptsButton.ImageIndex = 0
	$scriptsButton.ToolTipText = "Set scripts locations"
	$toolBar.Buttons.Add($scriptsButton)|Out-Null

	$connectButton.Name = "connectButton"
	$connectButton.ImageIndex = 1
	$connectButton.ToolTipText = "Connect to Exchange"
	$toolBar.Buttons.Add($connectButton)|Out-Null
	
	$helpButton.Name = "helpButton"
	$helpButton.ImageIndex = 2
	$helpButton.ToolTipText = "Help"
	$toolBar.Buttons.Add($helpButton)|Out-Null
	
	$refreshButton.Name = "refreshButton"
	$refreshButton.ImageIndex = 3
	$refreshButton.ToolTipText = "Refresh"
	$toolBar.Buttons.Add($refreshButton)|Out-Null
	#endregion Set Tool Bar Properties
	
	#region Generate Tree Nodes
	$pubFolMigNode.Name="pubFolMigNode"
	$pubFolMigNode.Text = "Public Folder Migration"
	$pubFolMigNode.ImageIndex = 0
	$pubFolMigNode.SelectedImageIndex = 0
	$actionTreeView.Nodes.Add($pubFolMigNode)|Out-Null
	
	$migPubFolNode.Name="migPubFolNode"
	$migPubFolNode.Text = "Migrate Public Folders"
	$migPubFolNode.ImageIndex = 1
	$migPubFolNode.SelectedImageIndex = 1
	$pubFolMigNode.Nodes.Add($migPubFolNode)|Out-Null
	
	$verMigNode.Name="verMigNode"
	$verMigNode.Text = "Verify Migration"
	$verMigNode.ImageIndex = 2
	$verMigNode.SelectedImageIndex = 2
	$pubFolMigNode.Nodes.Add($verMigNode)|Out-Null
	
	$rolBacMigNode.Name="rolBacMigNode"
	$rolBacMigNode.Text = "Role Back Migration"
	$rolBacMigNode.ImageIndex = 3
	$rolBacMigNode.SelectedImageIndex = 3
	$pubFolMigNode.Nodes.Add($rolBacMigNode)|Out-Null
	
	$pubFolTooNode.Name="pubFolTooNode"
	$pubFolTooNode.Text = "Public Folder Tools"
	$pubFolTooNode.ImageIndex = 4
	$pubFolTooNode.SelectedImageIndex = 4
	$actionTreeView.Nodes.Add($pubFolTooNode)|Out-Null
	
	$pubFolNode.Name="pubFolNode"
	$pubFolNode.Text = "Public Folders"
	$pubFolNode.ImageIndex = 5
	$pubFolNode.SelectedImageIndex = 5
	$pubFolTooNode.Nodes.Add($pubFolNode)|Out-Null
	
	$pubFolDatNode.Name="pubFolDatNode"
	$pubFolDatNode.Text = "Public Folder Databases"
	$pubFolDatNode.ImageIndex = 6
	$pubFolDatNode.SelectedImageIndex = 6
	$pubFolTooNode.Nodes.Add($pubFolDatNode)|Out-Null
	
	$pubFolMaiNode.Name="pubFolMaiNode"
	$pubFolMaiNode.Text = "Public Folder Mailboxes"
	$pubFolMaiNode.ImageIndex = 7
	$pubFolMaiNode.SelectedImageIndex = 7
	$pubFolTooNode.Nodes.Add($pubFolMaiNode)|Out-Null
	#endregion Generate Tree Nodes

	#region Delcair popupForm Objects
	$popupForm = New-Object System.Windows.Forms.Form
	$popupOkButton = New-Object System.Windows.Forms.Button
	$popupDialogTextBox = New-Object System.Windows.Forms.TextBox
	#endregion Delcair popupForm Objects
	#region Set popupForm Properties
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 113
	$System_Drawing_Size.Width = 417
	$popupForm.ClientSize = $System_Drawing_Size
	$popupForm.ControlBox = $False
	$popupForm.FormBorderStyle = 1
	$popupForm.Name = "popupForm"
	$popupForm.StartPosition = 1
	$popupForm.TopMost = $True

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 330
	$System_Drawing_Point.Y = 78
	$popupOkButton.Location = $System_Drawing_Point
	$popupOkButton.Name = "popupOkButton"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 75
	$popupOkButton.Size = $System_Drawing_Size
	$popupOkButton.Text = "OK"
	$popupOkButton.UseVisualStyleBackColor = $True
	$popupOkButton.add_Click({$popupForm.Close()})
	$popupForm.Controls.Add($popupOkButton)

	$popupDialogTextBox.BorderStyle = 0
	$popupDialogTextBox.Dock = 1
	$popupDialogTextBox.Multiline = $True
	$popupDialogTextBox.Name = "popupDialogTextBox"
	$popupDialogTextBox.ReadOnly = $True
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 60
	$popupDialogTextBox.Size = $System_Drawing_Size
	$popupDialogTextBox.TextAlign = 2
	$popupForm.Controls.Add($popupDialogTextBox)
	#endregion Set popupForm Properties

	#region Declair pubFol Objects
	$pubFolTreeView = New-Object System.Windows.Forms.TreeView
	$pubFolSplitter = New-Object System.Windows.Forms.Splitter
	$pubFolDataGridView = New-Object System.Windows.Forms.DataGridView
	$pubFolLabel = New-Object System.Windows.Forms.Label
	$pubFolAttDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	$pubFolValDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	#endregion Declair pubFol Objects
	#region Set pubFol Properties
	$pubFolTreeView.Dock = 5
	$pubFolTreeView.ImageList = $extraList
	$pubFolTreeView.Add_NodeMouseClick({GetPubFolNodeAttributes $_.Node.Tag})
	$displayPanel.Controls.Add($pubFolTreeView)
	
	$pubFolSplitter.DataBindings.DefaultDataSourceUpdateMode = 0
	$pubFolSplitter.Dock = 4
	$pubFolSplitter.Name = "pubFolSplitter"
	$displayPanel.Controls.Add($pubFolSplitter)
	
	$pubFolAttDataGridViewColumn.HeaderText = "Attribute"
	$pubFolAttDataGridViewColumn.Name = "attribute"
	$pubFolDataGridView.Columns.Add($pubFolAttDataGridViewColumn)|Out-Null
	
	$pubFolValDataGridViewColumn.HeaderText = "Value"
	$pubFolValDataGridViewColumn.Name = "value"
	$pubFolDataGridView.Columns.Add($pubFolValDataGridViewColumn)|Out-Null

	$pubFolDataGridView.Dock = 4
	$pubFolDataGridView.Name = "pubFolDataGridView"
	$pubFolDataGridView.AutoSizeColumnsMode = 16
	$pubFolDataGridView.AllowUserToAddRows = $False
	$pubFolDataGridView.AllowUserToDeleteRows = $False
	$pubFolDataGridView.AllowUserToResizeRows = $False
	$pubFolDataGridView.ReadOnly = $True
	$pubFolDataGridView.BorderStyle = 0
	$pubFolDataGridView.Add_CellClick({$pubFolDataGridView.ClearSelection()})
	$displayPanel.Controls.Add($pubFolDataGridView)
	
	$pubFolLabel.Dock = 1
	$pubFolLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",9,1,3,0)
	$pubFolLabel.Name = "label1"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$pubFolLabel.Size = $System_Drawing_Size
	$pubFolLabel.Text = ""
	$pubFolLabel.TextAlign = 32
	$displayPanel.Controls.Add($pubFolLabel)
	#endregion Set pubFol Properties
	
	#region Declair pubFolDat Objects
	$pubFolDatDataGridView = New-Object System.Windows.Forms.DataGridView
	$pubFolDatNamDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	$pubFolDatSerDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	$pubFolDatMouDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	$pubFolDatSizDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	$pubFolDatMaxDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	#endregion Declair pubFolDat Objects
	#region Set pubFolDat Properties
	$pubFolDatNamDataGridViewColumn.HeaderText = "Name"
	$pubFolDatNamDataGridViewColumn.Name = "name"
	$pubFolDatDataGridView.Columns.Add($pubFolDatNamDataGridViewColumn)|Out-Null
	
	$pubFolDatSerDataGridViewColumn.HeaderText = "Server Name"
	$pubFolDatSerDataGridViewColumn.Name = "servername"
	$pubFolDatDataGridView.Columns.Add($pubFolDatSerDataGridViewColumn)|Out-Null
	
	$pubFolDatMouDataGridViewColumn.HeaderText = "Mounted"
	$pubFolDatMouDataGridViewColumn.Name = "mounted"
	$pubFolDatDataGridView.Columns.Add($pubFolDatMouDataGridViewColumn)|Out-Null
	
	$pubFolDatSizDataGridViewColumn.HeaderText = "Database Size"
	$pubFolDatSizDataGridViewColumn.Name = "databasesize"
	$pubFolDatDataGridView.Columns.Add($pubFolDatSizDataGridViewColumn)|Out-Null
	
	$pubFolDatMaxDataGridViewColumn.HeaderText = "Max Item Size"
	$pubFolDatMaxDataGridViewColumn.Name = "maxitemsize"
	$pubFolDatDataGridView.Columns.Add($pubFolDatMaxDataGridViewColumn)|Out-Null
	
	$pubFolDatDataGridView.Dock = 5
	$pubFolDatDataGridView.Name = "pubFolDatDataGridView"
	$pubFolDatDataGridView.AutoSizeColumnsMode = 16
	$pubFolDatDataGridView.BackgroundColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
	$pubFolDatDataGridView.CellBorderStyle = 4
	$pubFolDatDataGridView.AllowUserToAddRows = $False
	$pubFolDatDataGridView.AllowUserToDeleteRows = $False
	$pubFolDatDataGridView.AllowUserToResizeRows = $False
	$pubFolDatDataGridView.ReadOnly = $True
	$pubFolDatDataGridView.BorderStyle = 0
	$pubFolDatDataGridView.RowHeadersVisible = $False
	$pubFolDatDataGridView.Add_CellClick({$pubFolDatDataGridView.ClearSelection()})
	$displayPanel.Controls.Add($pubFolDatDataGridView)
	#endregion Set pubFolDat Properties

	#region Declair pubFolMai Objects
	$pubFolMaiDataGridView = New-Object System.Windows.Forms.DataGridView
	$pubFolMaiSplitter = New-Object System.Windows.Forms.Splitter
	$pubFolMaiAttDataGridView = New-Object System.Windows.Forms.DataGridView
	$pubFolMaiNamDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	$pubFolMaiDatDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	$pubFolMaiMouDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	$pubFolMaiSerDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	$pubFolMaiAttDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	$pubFolMaiValDataGridViewColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
	#endregion Declair pubFolMai Objects
	#region Set pubFoldMai Properties
	$pubFolMaiNamDataGridViewColumn.HeaderText = "Name"
	$pubFolMaiNamDataGridViewColumn.Name = "name"
	$pubFolMaiDataGridView.Columns.Add($pubFolMaiNamDataGridViewColumn)|Out-Null
	
	$pubFolMaiDatDataGridViewColumn.HeaderText = "Database"
	$pubFolMaiDatDataGridViewColumn.Name = "database"
	$pubFolMaiDataGridView.Columns.Add($pubFolMaiDatDataGridViewColumn)|Out-Null
	
	$pubFolMaiMouDataGridViewColumn.HeaderText = "Mounted on Server"
	$pubFolMaiMouDataGridViewColumn.Name = "mountedonserver"
	$pubFolMaiDataGridView.Columns.Add($pubFolMaiMouDataGridViewColumn)|Out-Null
	
	$pubFolMaiSerDataGridViewColumn.HeaderText = "Servers"
	$pubFolMaiSerDataGridViewColumn.Name = "servers"
	$pubFolMaiDataGridView.Columns.Add($pubFolMaiSerDataGridViewColumn)|Out-Null
	
	$pubFolMaiDataGridView.Dock = 5
	$pubFolMaiDataGridView.Name = "pubFolMaiDataGridView"
	$pubFolMaiDataGridView.AutoSizeColumnsMode = 16
	$pubFolMaiDataGridView.BackgroundColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
	$pubFolMaiDataGridView.CellBorderStyle = 4
	$pubFolMaiDataGridView.AllowUserToAddRows = $False
	$pubFolMaiDataGridView.AllowUserToDeleteRows = $False
	$pubFolMaiDataGridView.AllowUserToResizeRows = $False
	$pubFolMaiDataGridView.ReadOnly = $True
	$pubFolMaiDataGridView.BorderStyle = 0
	$pubFolMaiDataGridView.RowHeadersVisible = $False
	$pubFolMaiDataGridView.Add_CellMouseDown({GetPubFolMaiCellAttributes $_})
	$pubFolMaiDataGridView.Add_CellMouseUp({GetPubFolMaiCellSelect $_})
	$displayPanel.Controls.Add($pubFolMaiDataGridView)
	
	$pubFolMaiSplitter.DataBindings.DefaultDataSourceUpdateMode = 0
	$pubFolMaiSplitter.Dock = 4
	$pubFolMaiSplitter.Name = "pubFolMaiSplitter"
	$displayPanel.Controls.Add($pubFolMaiSplitter)
	
	$pubFolMaiAttDataGridViewColumn.HeaderText = "Attribute"
	$pubFolMaiAttDataGridViewColumn.Name = "attribute"
	$pubFolMaiAttDataGridView.Columns.Add($pubFolMaiAttDataGridViewColumn)|Out-Null
	
	$pubFolMaiValDataGridViewColumn.HeaderText = "Value"
	$pubFolMaiValDataGridViewColumn.Name = "value"
	$pubFolMaiAttDataGridView.Columns.Add($pubFolMaiValDataGridViewColumn)|Out-Null

	$pubFolMaiAttDataGridView.Dock = 4
	$pubFolMaiAttDataGridView.Name = "pubFolMaiAttDataGridView"
	$pubFolMaiAttDataGridView.AutoSizeColumnsMode = 16
	$pubFolMaiAttDataGridView.AllowUserToAddRows = $False
	$pubFolMaiAttDataGridView.AllowUserToDeleteRows = $False
	$pubFolMaiAttDataGridView.AllowUserToResizeRows = $False
	$pubFolMaiAttDataGridView.ReadOnly = $True
	$pubFolMaiAttDataGridView.BorderStyle = 0
	$pubFolMaiAttDataGridView.Add_CellClick({$pubFolMaiAttDataGridView.ClearSelection()})
	$displayPanel.Controls.Add($pubFolMaiAttDataGridView)
	#endregion Set pubFoldMai Properties

	#region Declair migPubFol Objects
	$migPubFolTabControl = New-Object System.Windows.Forms.TabControl
	$snapshotTabPage = New-Object System.Windows.Forms.TabPage
	$replaceTabPage = New-Object System.Windows.Forms.TabPage
	$checkTabPage = New-Object System.Windows.Forms.TabPage
	$generateTabPage = New-Object System.Windows.Forms.TabPage
	$createTabPage = New-Object System.Windows.Forms.TabPage
	$assignTabPage = New-Object System.Windows.Forms.TabPage
	$startMigrationTabPage = New-Object System.Windows.Forms.TabPage
	$progressTabPage = New-Object System.Windows.Forms.TabPage
	$finalizeMigrationTabPage = New-Object System.Windows.Forms.TabPage
	$completedTabPage = New-Object System.Windows.Forms.TabPage
	
	$startButton = New-Object System.Windows.Forms.Button
	$snapshotDialogBox = New-Object System.Windows.Forms.TextBox
	
	$replacePanel = New-Object System.Windows.Forms.Panel
	$replaceListView = New-Object System.Windows.Forms.ListView
	$replaceTextBox = New-Object System.Windows.Forms.TextBox
	$replaceLabel = New-Object System.Windows.Forms.Label
	$reloadButton = New-Object System.Windows.Forms.Button
	$replaceButton = New-Object System.Windows.Forms.Button
	$replaceDialogBox = New-Object System.Windows.Forms.TextBox
	
	$chekPanel = New-Object System.Windows.Forms.Panel
	$checkDialogTextBox = New-Object System.Windows.Forms.TextBox
	$pfmxLabel = New-Object System.Windows.Forms.Label
	$pfmrResultLabel = New-Object System.Windows.Forms.Label
	$pfmcResultLabel = New-Object System.Windows.Forms.Label
	$pflfmResultLabel = New-Object System.Windows.Forms.Label
	$pfmxListView = New-Object System.Windows.Forms.ListView
	$pfmrLabel = New-Object System.Windows.Forms.Label
	$pfmcLabel = New-Object System.Windows.Forms.Label
	$pflfmLabel = New-Object System.Windows.Forms.Label
	$clearButton = New-Object System.Windows.Forms.Button
	
	$bytesLabel = New-Object System.Windows.Forms.Label
	$maxMxSizeTextBox = New-Object System.Windows.Forms.TextBox
	$maxMxSizeLabel = New-Object System.Windows.Forms.Label
	$generateDialogTextBox = New-Object System.Windows.Forms.TextBox
	$generateButton = New-Object System.Windows.Forms.Button
	
	$createTreeView = New-Object System.Windows.Forms.TreeView
	$createDialogTextBox = New-Object System.Windows.Forms.TextBox
	$createPanel = New-Object System.Windows.Forms.Panel
	$createButton = New-Object System.Windows.Forms.Button

	$assignGroupPanel = New-Object System.Windows.Forms.Panel
	$assignGroupBox = New-Object System.Windows.Forms.GroupBox
	$assignIsRootLabel = New-Object System.Windows.Forms.Label
	$assignDatabaseLabel = New-Object System.Windows.Forms.Label
	$assignMailboxLabel = New-Object System.Windows.Forms.Label
	$assignDialogTextBox = New-Object System.Windows.Forms.TextBox
	$assignPanel = New-Object System.Windows.Forms.Panel
	$refreshButton = New-Object System.Windows.Forms.Button
	
	$migrateButton = New-Object System.Windows.Forms.Button
	$startDialogTextBox = New-Object System.Windows.Forms.TextBox

	$migProgressProgressBar = New-Object System.Windows.Forms.ProgressBar
	$migProgressLabel = New-Object System.Windows.Forms.Label
	$migProgressStepLabel = New-Object System.Windows.Forms.Label
	$migPrepProgressBar = New-Object System.Windows.Forms.ProgressBar
	$migPrepLabel = New-Object System.Windows.Forms.Label
	$migPrepStepLabel = New-Object System.Windows.Forms.Label
	$progressDialogTextBox = New-Object System.Windows.Forms.TextBox

	$finalizeButton = New-Object System.Windows.Forms.Button
	$forceButton = New-Object System.Windows.Forms.Button
	$finalizeProgressBar = New-Object System.Windows.Forms.ProgressBar
	$finalizeStepLabel = New-Object System.Windows.Forms.Label
	$finalizeListView = New-Object System.Windows.Forms.ListView
	$finalizeDialogTextBox = New-Object System.Windows.Forms.TextBox
	
	$completedDialogTextBox = New-Object System.Windows.Forms.TextBox
	#endregion Declair migPubFol Objects
	#region Set migPubFol Properties
	$migPubFolTabControl.Appearance = 1
	$migPubFolTabControl.Dock = 5
	$migPubFolTabControl.Name = "migPubFolTabControl"
	$migPubFolTabControl.SizeMode = 2
	$migPubFolTabControl.add_Selecting({$_.Cancel = !$_.TabPage.Enabled})
	$displayPanel.Controls.Add($migPubFolTabControl)

	$snapshotTabPage.Name = "snapshotTabPage"
	$snapshotTabPage.Text = "Snapshot"
	$snapshotTabPage.UseVisualStyleBackColor = $True
	$migPubFolTabControl.Controls.Add($snapshotTabPage)

	$replaceTabPage.Name = "replaceTabPage"
	$replaceTabPage.Text = "Replace"
	$replaceTabPage.UseVisualStyleBackColor = $True
	$migPubFolTabControl.Controls.Add($replaceTabPage)

	$checkTabPage.Name = "checkTabPage"
	$checkTabPage.Text = "Check"
	$checkTabPage.UseVisualStyleBackColor = $True
	$checkTabPage.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",8,0,3,0)
	$migPubFolTabControl.Controls.Add($checkTabPage)

	$generateTabPage.Name = "generateTabPage"
	$generateTabPage.Text = "Generate"
	$generateTabPage.UseVisualStyleBackColor = $True
	$migPubFolTabControl.Controls.Add($generateTabPage)

	$createTabPage.Name = "createTabPage"
	$createTabPage.Text = "Create"
	$createTabPage.UseVisualStyleBackColor = $True
	$migPubFolTabControl.Controls.Add($createTabPage)

	$assignTabPage.Name = "assignTabPage"
	$assignTabPage.Text = "Assign"
	$assignTabPage.UseVisualStyleBackColor = $True
	$migPubFolTabControl.Controls.Add($assignTabPage)

	$startMigrationTabPage.Name = "startMigrationTabPage"
	$startMigrationTabPage.Text = "Start Migration"
	$startMigrationTabPage.UseVisualStyleBackColor = $True
	$migPubFolTabControl.Controls.Add($startMigrationTabPage)

	$progressTabPage.Name = "progressTabPage"
	$progressTabPage.Text = "Progress"
	$progressTabPage.UseVisualStyleBackColor = $True
	$migPubFolTabControl.Controls.Add($progressTabPage)
	
	$finalizeMigrationTabPage.Name = "finalizeMigrationTabPage"
	$finalizeMigrationTabPage.Text = "Finalize Migration"
	$finalizeMigrationTabPage.UseVisualStyleBackColor = $True
	$migPubFolTabControl.Controls.Add($finalizeMigrationTabPage)

	$completedTabPage.Name = "completedTabPage"
	$completedTabPage.Text = "Completed Migration"
	$completedTabPage.UseVisualStyleBackColor = $True
	$migPubFolTabControl.Controls.Add($completedTabPage)
	
	$startButton.Anchor = 9
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 110
	$System_Drawing_Point.Y = 306
	$startButton.Location = $System_Drawing_Point
	$startButton.Name = "startButton"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 75
	$startButton.Size = $System_Drawing_Size
	$startButton.Text = "Start"
	$startButton.UseVisualStyleBackColor = $True
	$startButton.add_Click({startButtonClick})
	$snapshotTabPage.Controls.Add($startButton)

	$snapshotDialogBox.Dock = 1
	$snapshotDialogBox.Multiline = $True
	$snapshotDialogBox.Name = "snapshotDialogBox"
	$snapshotDialogBox.Cursor = [System.Windows.Forms.Cursors]::Arrow
	$snapshotDialogBox.ReadOnly = $True
	$snapshotDialogBox.TabStop = $False
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 300
	$snapshotDialogBox.Size = $System_Drawing_Size
	$snapshotDialogBox.Text="Welcome to the beginning of the migration of public folders from Exchange 2010 public folder databases to Exchange 2013 public folder mailboxes. During this process, you will be running through the following steps:

	• Taking a snapshot of your current public folder structure, statistics, and permissions.
	• Checking for and renaming any public folders that contain the '\' character.
	• Checking for and clearing any migrations currently in progress.
	• Generating a map of public folders to their new home in mailboxes.
	• Creating the proper public folder mailboxes for your environment.
	• Starting the migration process.
	• Finalizing the migration process.

One you are finished, you will have the opportunity to verify or roll back the migration. To begin, click the 'Start' button and a snapshot will be taken of your current public folder environment."
	$snapshotTabPage.Controls.Add($snapshotDialogBox)

	$replacePanel.Dock = 1
	$replacePanel.Name = "replacePanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 200
	$replacePanel.Size = $System_Drawing_Size
	$replaceTabPage.Controls.Add($replacePanel)

	$replaceListView.Dock = 2
	$replaceListView.SmallImageList = $extraList
	$replaceListView.Name = "replaceListView"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 150
	$replaceListView.Size = $System_Drawing_Size
	$replaceListView.UseCompatibleStateImageBehavior = $False
	$replaceListView.View = 3
	$replaceListView.Add_MouseDown({CreateReplaceContextMenu $this $_})
	$replacePanel.Controls.Add($replaceListView)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 128
	$System_Drawing_Point.Y = 16
	$replaceTextBox.Location = $System_Drawing_Point
	$replaceTextBox.MaxLength = 10
	$replaceTextBox.Name = "replaceTextBox"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 20
	$System_Drawing_Size.Width = 85
	$replaceTextBox.Size = $System_Drawing_Size
	$replaceTextBox.Text = "-"
	$replaceTextBox.add_TextChanged({
		$replaceTextBox.Text=$replaceTextBox.Text.replace("\","")
	})
	$replacePanel.Controls.Add($replaceTextBox)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 12
	$System_Drawing_Point.Y = 14
	$replaceLabel.Location = $System_Drawing_Point
	$replaceLabel.Name = "replaceLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 150
	$replaceLabel.Size = $System_Drawing_Size
	$replaceLabel.Text = "Character to user:"
	$replaceLabel.TextAlign = 16
	$replacePanel.Controls.Add($replaceLabel)

	$reloadButton.Anchor = 9
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 30
	$System_Drawing_Point.Y = 356
	$reloadButton.Location = $System_Drawing_Point
	$reloadButton.Name = "reloadButton"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 75
	$reloadButton.Size = $System_Drawing_Size
	$reloadButton.Text = "Reload"
	$reloadButton.UseVisualStyleBackColor = $True
	$reloadButton.add_Click({reloadButtonClick})
	$replaceTabPage.Controls.Add($reloadButton)

	$replaceButton.Anchor = 9
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 110
	$System_Drawing_Point.Y = 356
	$replaceButton.Location = $System_Drawing_Point
	$replaceButton.Name = "replaceButton"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 75
	$replaceButton.Size = $System_Drawing_Size
	$replaceButton.Text = "Replace"
	$replaceButton.UseVisualStyleBackColor = $True
	$replaceButton.add_Click({replaceButtonClick})
	$replaceTabPage.Controls.Add($replaceButton)

	$replaceDialogBox.Dock = 1
	$replaceDialogBox.Multiline = $True
	$replaceDialogBox.Name = "replaceDialogBox"
	$replaceDialogBox.ReadOnly = $True
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 150
	$replaceDialogBox.Size = $System_Drawing_Size
	$replaceDialogBox.Text = "The next step is to replace all instances of the '\' character in the names of the public folders as this character is not supported. Check the list at the bottom of the page. If this list is empty, simply click the 'Replace' button to skip this section. Otherwise, select the character you would like to use to replace the '\' character. The default is '-'.
You can also right click the public folders in the list to rename them manually.
Click the 'Reload' button to get a refreshed list of pubic folder left to rename."
	$replaceTabPage.Controls.Add($replaceDialogBox)
	
	$chekPanel.Dock = 1
	$chekPanel.Name = "chekPanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 350
	$chekPanel.Size = $System_Drawing_Size
	$checkTabPage.Controls.Add($chekPanel)

	$checkDialogTextBox.Dock = 1
	$checkDialogTextBox.Multiline = $True
	$checkDialogTextBox.Name = "checkDialogTextBox"
	$checkDialogTextBox.ReadOnly = $True
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 75
	$checkDialogTextBox.Size = $System_Drawing_Size
	$checkDialogTextBox.Text = "This page displays any previous migrations attempts that must be cleared before proceeding with a complete migration.
	
By clicking 'Clear Migration' you will remove all migration flags and requests, and delete any existing public folder mailboxes. If you would like to keep any of the public folder mailboxes, choose 'Save This Mailbox' in the context menu."
	$chekPanel.Controls.Add($checkDialogTextBox)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 16
	$System_Drawing_Point.Y = 90
	$pflfmLabel.Location = $System_Drawing_Point
	$pflfmLabel.Name = "pflfmLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 184
	$pflfmLabel.Size = $System_Drawing_Size
	$pflfmLabel.Text = "Public Folders Locked for Migration:"
	$chekPanel.Controls.Add($pflfmLabel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 206
	$System_Drawing_Point.Y = 90
	$pflfmResultLabel.Location = $System_Drawing_Point
	$pflfmResultLabel.Name = "pflfmResultLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 100
	$pflfmResultLabel.Size = $System_Drawing_Size
	$chekPanel.Controls.Add($pflfmResultLabel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 16
	$System_Drawing_Point.Y = 140
	$pfmcLabel.Location = $System_Drawing_Point
	$pfmcLabel.Name = "pfmcLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 184
	$pfmcLabel.Size = $System_Drawing_Size
	$pfmcLabel.Text = "Public Folder Migration Complete:"
	$chekPanel.Controls.Add($pfmcLabel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 206
	$System_Drawing_Point.Y = 140
	$pfmcResultLabel.Location = $System_Drawing_Point
	$pfmcResultLabel.Name = "pfmcResultLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 100
	$pfmcResultLabel.Size = $System_Drawing_Size
	$chekPanel.Controls.Add($pfmcResultLabel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 16
	$System_Drawing_Point.Y = 190
	$pfmrLabel.Location = $System_Drawing_Point
	$pfmrLabel.Name = "pfmrLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 184
	$pfmrLabel.Size = $System_Drawing_Size
	$pfmrLabel.Text = "Public Folder Migration Request:"
	$chekPanel.Controls.Add($pfmrLabel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 206
	$System_Drawing_Point.Y = 190
	$pfmrResultLabel.Location = $System_Drawing_Point
	$pfmrResultLabel.Name = "pfmrResultLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 467
	$pfmrResultLabel.Size = $System_Drawing_Size
	$chekPanel.Controls.Add($pfmrResultLabel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 5
	$System_Drawing_Point.Y = 234
	$pfmxLabel.Location = $System_Drawing_Point
	$pfmxLabel.Name = "pfmxLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 184
	$pfmxLabel.Size = $System_Drawing_Size
	$pfmxLabel.Text = "Public Folder Mailboxes:"
	$chekPanel.Controls.Add($pfmxLabel)

	$pfmxListView.Dock = 2
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 0
	$System_Drawing_Point.Y = 260
	$pfmxListView.Location = $System_Drawing_Point
	$pfmxListView.Name = "pfmxListView"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 90
	$System_Drawing_Size.Width = 787
	$pfmxListView.Size = $System_Drawing_Size
	$pfmxListView.UseCompatibleStateImageBehavior = $False
	$pfmxListView.View = 3
	$pfmxListView.SmallImageList = $extraList
	$pfmxListView.Add_MouseDown({CreateCheckContextMenu $this $_})
	$chekPanel.Controls.Add($pfmxListView)

	$clearButton.Anchor = 9
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 90
	$System_Drawing_Point.Y = 356
	$clearButton.Location = $System_Drawing_Point
	$clearButton.Name = "clearButton"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 100
	$clearButton.Size = $System_Drawing_Size
	$clearButton.Text = "Clear Migration"
	$clearButton.UseVisualStyleBackColor = $True
	$clearButton.add_Click({clearButtonClick})
	$checkTabPage.Controls.Add($clearButton)
	
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 282
	$System_Drawing_Point.Y = 176
	$bytesLabel.Location = $System_Drawing_Point
	$bytesLabel.Name = "bytesLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 100
	$bytesLabel.Size = $System_Drawing_Size
	$bytesLabel.Text = "MB"
	$bytesLabel.TextAlign = 16
	$generateTabPage.Controls.Add($bytesLabel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 129
	$System_Drawing_Point.Y = 178
	$maxMxSizeTextBox.Location = $System_Drawing_Point
	$maxMxSizeTextBox.Name = "maxMxSizeTextBox"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 20
	$System_Drawing_Size.Width = 147
	$maxMxSizeTextBox.Size = $System_Drawing_Size
	$maxMxSizeTextBox.Text = "2000"
	$maxMxSizeTextBox.add_TextChanged({
		[long]$num=$null
		if(!([long]::TryParse($maxMxSizeTextBox.Text,[ref]$num))){$maxMxSizeTextBox.Text="2000"}
	})
	$generateTabPage.Controls.Add($maxMxSizeTextBox)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 13
	$System_Drawing_Point.Y = 176
	$maxMxSizeLabel.Location = $System_Drawing_Point
	$maxMxSizeLabel.Name = "maxMxSizeLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 120
	$maxMxSizeLabel.Size = $System_Drawing_Size
	$maxMxSizeLabel.Text = "Max Mailbox Size:"
	$maxMxSizeLabel.TextAlign = 16
	$generateTabPage.Controls.Add($maxMxSizeLabel)

	$generateDialogTextBox.Dock = 1
	$generateDialogTextBox.Multiline = $True
	$generateDialogTextBox.Name = "generateDialogTextBox"
	$generateDialogTextBox.ReadOnly = $True
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 150
	$generateDialogTextBox.Size = $System_Drawing_Size
	$generateDialogTextBox.Text = "Select the max size in MB for the public folder mailboxes. This will be used for the initial mapping and creation of the public folder mailboxes.

When specifying this setting, be sure to allow for expansion so the public folder mailbox has room to grow."
	$generateTabPage.Controls.Add($generateDialogTextBox)

	$generateButton.Anchor = 9
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 110
	$System_Drawing_Point.Y = 236
	$generateButton.Location = $System_Drawing_Point
	$generateButton.Name = "generateButton"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 75
	$generateButton.Size = $System_Drawing_Size
	$generateButton.Text = "Generate"
	$generateButton.UseVisualStyleBackColor = $True
	$generateButton.add_Click({generateButtonClick})
	$generateTabPage.Controls.Add($generateButton)

	$createTreeView.Dock = 5
	$createTreeView.Name = "createTreeView"
	$createTreeView.ImageList = $extraList
	$createTreeView.AllowDrop = $True
	$createTreeView.add_DragEnter({
		$_.Effect=$_.AllowedEffect
		$createTreeView.selectednode=$_.Data.GetData([System.Windows.Forms.TreeNode])
	})
	$createTreeView.add_ItemDrag({
		$createTreeView.DoDragDrop($_.Item, [System.Windows.Forms.DragDropEffects]::Move)
	})
	$createTreeView.add_DragDrop({MovePublicFolderMailboxAssignment $_})
	$createTreeView.add_NodeMouseClick({
		$createTreeView.SelectedNode=$_.Node
	})
	$createTabPage.Controls.Add($createTreeView)

	$createDialogTextBox.Dock = 1
	$createDialogTextBox.Multiline = $True
	$createDialogTextBox.Name = "createDialogTextBox"
	$createDialogTextBox.ReadOnly = $True
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 120
	$createDialogTextBox.Size = $System_Drawing_Size
	$createDialogTextBox.Text = "Use the following tree to organize your public folders into public folder mailboxes.
Right click a public folder mailbox if you would like to:
	• Rename the public folder mailbox.
	• Delete the public folder mailbox.
	• Create a new public folder mailbox.
	• Save the public folder mailbox mapping file.
You can also view the size of the mailbox next to it's name (size taken from the folder size mapping file).
Warning: If you click the 'Refresh' button, all changes will be cleared unless saved first."
	$createTabPage.Controls.Add($createDialogTextBox)

	$createPanel.Dock = 2
	$createPanel.Name = "createPanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 50
	$createPanel.Size = $System_Drawing_Size
	$createTabPage.Controls.Add($createPanel)

	$createButton.Anchor = 10
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 110
	$System_Drawing_Point.Y = 15
	$createButton.Location = $System_Drawing_Point
	$createButton.Name = "createButton"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 75
	$createButton.Size = $System_Drawing_Size
	$createButton.Text = "Save"
	$createButton.UseVisualStyleBackColor = $True
	$createButton.add_Click({createButtonClick})
	$createPanel.Controls.Add($createButton)

#	$assignGroupBox.AutoSize = $True
	$assignGroupBox.Dock = 5
	$assignGroupBox.Name = "assignGroupBox"
	$assignGroupBox.TabStop = $False
	$assignTabPage.Controls.Add($assignGroupBox)

	$assignGroupPanel.Dock = 5
	$assignGroupPanel.AutoScroll = $True
	$assignGroupPanel.Name = "assignPanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 50
	$assignGroupPanel.Size = $System_Drawing_Size
	$assignGroupBox.Controls.Add($assignGroupPanel)
	
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 364
	$System_Drawing_Point.Y = 20
	$assignIsRootLabel.Location = $System_Drawing_Point
	$assignIsRootLabel.Name = "assignIsRootLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 100
	$assignIsRootLabel.Size = $System_Drawing_Size
	$assignIsRootLabel.Text = "Is Root:"
	$assignIsRootLabel.TextAlign = 32
	$assignGroupPanel.Controls.Add($assignIsRootLabel)
	
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 208
	$System_Drawing_Point.Y = 20
	$assignDatabaseLabel.Location = $System_Drawing_Point
	$assignDatabaseLabel.Name = "assignDatabaseLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 150
	$assignDatabaseLabel.Size = $System_Drawing_Size
	$assignDatabaseLabel.Text = "Mailbox Database:"
	$assignDatabaseLabel.TextAlign = 32
	$assignGroupPanel.Controls.Add($assignDatabaseLabel)
	
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 52
	$System_Drawing_Point.Y = 20
	$assignMailboxLabel.Location = $System_Drawing_Point
	$assignMailboxLabel.Name = "assignMailboxLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 150
	$assignMailboxLabel.Size = $System_Drawing_Size
	$assignMailboxLabel.Text = "Public Folder Mailbox:"
	$assignMailboxLabel.TextAlign = 32
	$assignGroupPanel.Controls.Add($assignMailboxLabel)
	
	$assignDialogTextBox.Dock = 1
	$assignDialogTextBox.Multiline = $True
	$assignDialogTextBox.Name = "assignDialogTextBox"
	$assignDialogTextBox.ReadOnly = $True
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 120
	$assignDialogTextBox.Size = $System_Drawing_Size
	$assignDialogTextBox.Text = "This page is used to assign the public folder mailboxes to databases in your 2013 environment.

If changes have been made to the 'Create' page:
	Click the 'Save' button on the 'Create' page.
	Click the 'Refresh' button on the 'Assign' page.

The 'Is Root' property determines the primary hierarchy mailbox for the public folders."
	$assignTabPage.Controls.Add($assignDialogTextBox)
	
	$assignPanel.Dock = 2
	$assignPanel.Name = "assignPanel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 50
	$assignPanel.Size = $System_Drawing_Size
	$assignTabPage.Controls.Add($assignPanel)
	
	$refreshButton.Anchor = 10
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 110
	$System_Drawing_Point.Y = 15
	$refreshButton.Location = $System_Drawing_Point
	$refreshButton.Name = "refreshButton"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 75
	$refreshButton.Size = $System_Drawing_Size
	$refreshButton.Text = "Refresh"
	$refreshButton.UseVisualStyleBackColor = $True
	$refreshButton.add_Click({GetMailboxDatabaseAssignment})
	$assignPanel.Controls.Add($refreshButton)

	$migrateButton.Anchor = 9
	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 110
	$System_Drawing_Point.Y = 150
	$migrateButton.Location = $System_Drawing_Point
	$migrateButton.Name = "migrateButton"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 75
	$migrateButton.Size = $System_Drawing_Size
	$migrateButton.Text = "Migrate"
	$migrateButton.UseVisualStyleBackColor = $True
	$migrateButton.add_Click({migrateButtonClick})
	$startMigrationTabPage.Controls.Add($migrateButton)

	$startDialogTextBox.Dock = 1
	$startDialogTextBox.Multiline = $True
	$startDialogTextBox.Name = "startDialogTextBox"
	$startDialogTextBox.ReadOnly = $True
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 120
	$startDialogTextBox.Size = $System_Drawing_Size
	$startDialogTextBox.Text = "`r`nClick the 'Migrate' button to start the public folder migration to Exchange 2013.

Before continuing, verify the following:
	• The public folder's have the correct mailbox mapping.
	• The public folder mailboxes have the correct database assignment.
	• The correct mailbox is set as the primary hierarchy mailbox."
	$startMigrationTabPage.Controls.Add($startDialogTextBox)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 170
	$System_Drawing_Point.Y = 318
	$migProgressProgressBar.Location = $System_Drawing_Point
	$migProgressProgressBar.Name = "migProgressProgressBar"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 350
	$migProgressProgressBar.Size = $System_Drawing_Size
	$progressTabPage.Controls.Add($migProgressProgressBar)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 54
	$System_Drawing_Point.Y = 318
	$migProgressLabel.Location = $System_Drawing_Point
	$migProgressLabel.Name = "migProgressLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 110
	$migProgressLabel.Size = $System_Drawing_Size
	$migProgressLabel.Text = "Migration progress:"
	$migProgressLabel.TextAlign = 64
	$progressTabPage.Controls.Add($migProgressLabel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 170
	$System_Drawing_Point.Y = 264
	$migProgressStepLabel.Location = $System_Drawing_Point
	$migProgressStepLabel.Name = "migProgressStepLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 350
	$migProgressStepLabel.Size = $System_Drawing_Size
	$migProgressStepLabel.TextAlign = 32
	$progressTabPage.Controls.Add($migProgressStepLabel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 170
	$System_Drawing_Point.Y = 206
	$migPrepProgressBar.Location = $System_Drawing_Point
	$migPrepProgressBar.Name = "migPrepProgressBar"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 350
	$migPrepProgressBar.Size = $System_Drawing_Size
	$progressTabPage.Controls.Add($migPrepProgressBar)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 54
	$System_Drawing_Point.Y = 206
	$migPrepLabel.Location = $System_Drawing_Point
	$migPrepLabel.Name = "migPrepLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 110
	$migPrepLabel.Size = $System_Drawing_Size
	$migPrepLabel.TabIndex = 3
	$migPrepLabel.Text = "Migration prep:"
	$migPrepLabel.TextAlign = 64
	$progressTabPage.Controls.Add($migPrepLabel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 170
	$System_Drawing_Point.Y = 160
	$migPrepStepLabel.Location = $System_Drawing_Point
	$migPrepStepLabel.Name = "migPrepStepLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 350
	$migPrepStepLabel.Size = $System_Drawing_Size
	$migPrepStepLabel.TextAlign = 32
	$progressTabPage.Controls.Add($migPrepStepLabel)

	$progressDialogTextBox.Dock = 1
	$progressDialogTextBox.Multiline = $True
	$progressDialogTextBox.Name = "progressDialogTextBox"
	$progressDialogTextBox.ReadOnly = $True
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 120
	$progressDialogTextBox.Size = $System_Drawing_Size
	$progressDialogTextBox.Text = "This page is used to display the progress of the public folder migration.

Once the Migration prep has completed, you may closed the Public Folder Migration Tool.

To get the progress of the public folder migration, click the Refresh button.

When the migration has finished, you will be automatically sent to the finalization page."
	$progressTabPage.Controls.Add($progressDialogTextBox)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 10
	$System_Drawing_Point.Y = 440
	$forceButton.Location = $System_Drawing_Point
	$forceButton.Name = "forceButton"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 75
	$forceButton.Size = $System_Drawing_Size
	$forceButton.Text = "Force"
	$forceButton.UseVisualStyleBackColor = $True
	$forceButton.Enabled = $false
	$forceButton.add_Click({ForceCompleteMigration})
	$progressTabPage.Controls.Add($forceButton)
#	$finalizeMigrationTabPage.Controls.Add($forceButton)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 110
	$System_Drawing_Point.Y = 440
	$finalizeButton.Location = $System_Drawing_Point
	$finalizeButton.Anchor = 9
	$finalizeButton.Name = "finalizeButton"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 75
	$finalizeButton.Size = $System_Drawing_Size
	$finalizeButton.Text = "Finalize"
	$finalizeButton.UseVisualStyleBackColor = $True
	$finalizeButton.Enabled = $false
	$finalizeButton.add_Click({finalizeButtonClick})
	$finalizeMigrationTabPage.Controls.Add($finalizeButton)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 120
	$System_Drawing_Point.Y = 400
	$finalizeProgressBar.Location = $System_Drawing_Point
	$finalizeProgressBar.Name = "finalizeProgressBar"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 350
	$finalizeProgressBar.Size = $System_Drawing_Size
	$finalizeMigrationTabPage.Controls.Add($finalizeProgressBar)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 120
	$System_Drawing_Point.Y = 360
	$finalizeStepLabel.Location = $System_Drawing_Point
	$finalizeStepLabel.Name = "finalizeStepLabel"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 23
	$System_Drawing_Size.Width = 350
	$finalizeStepLabel.Size = $System_Drawing_Size
	$finalizeStepLabel.TextAlign = 32
	$finalizeMigrationTabPage.Controls.Add($finalizeStepLabel)

	$System_Drawing_Point = New-Object System.Drawing.Point
	$System_Drawing_Point.X = 120
	$System_Drawing_Point.Y = 160
	$finalizeListView.Location = $System_Drawing_Point
	$finalizeListView.Name = "finalizeListView"
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 150
	$System_Drawing_Size.Width = 350
	$finalizeListView.Size = $System_Drawing_Size
	$finalizeListView.UseCompatibleStateImageBehavior = $False
	$finalizeListView.MultiSelect = $false
	$finalizeListView.View = 3
	$finalizeListView.add_ItemSelectionChanged({$finalizeButton.Enabled = $true})
	$finalizeMigrationTabPage.Controls.Add($finalizeListView)

	$finalizeDialogTextBox.Dock = 1
	$finalizeDialogTextBox.Multiline = $True
	$finalizeDialogTextBox.Name = "finalizeDialogTextBox"
	$finalizeDialogTextBox.ReadOnly = $True
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 120
	$finalizeDialogTextBox.Size = $System_Drawing_Size
	$finalizeDialogTextBox.Text = "The migration of the public folder data has completed.

To finalize the migration, choose a user to test with during the process and click the 'Finalize' button.

WARNING:
	The finalization process will require down time.
	Once you have finalized the migration, you can not role back to 2010 public folders."
	$finalizeMigrationTabPage.Controls.Add($finalizeDialogTextBox)

	$completedDialogTextBox.Dock = 1
	$completedDialogTextBox.Multiline = $True
	$completedDialogTextBox.Name = "completedDialogTextBox"
	$completedDialogTextBox.ReadOnly = $True
	$System_Drawing_Size = New-Object System.Drawing.Size
	$System_Drawing_Size.Height = 120
	$completedDialogTextBox.Size = $System_Drawing_Size
	$completedDialogTextBox.Text = "The public folder migration from Exchange 2010 to 2013 has completed.

If you would like to verify the migration, click on the 'Verify Migration' section."
	$completedTabPage.Controls.Add($completedDialogTextBox)
	#endregion Set migPubFol Properties
	
	#region toolBar Handlers
	$toolBar.add_ButtonClick({
		switch($_.Button.Name){
			"scriptsButton"{LoadScripts;EnableControls}
			"connectButton"{SetServers;EnableControls}
			"helpButton"{Write-Host "help!"}
			"refreshButton"{ApplyFilter}
		}
	})
	#endregion toolBar Handlers
	
	#region actionTreeView Handlers
	$actionTreeView.Add_NodeMouseClick({
		if($actionTreeView.SelectedNode.Name -eq $_.Node.Name){Return}
		$actionTreeView.SelectedNode=$actionTreeView|?{$_.Name -eq $_.Node.Name}
		SetObjectAvailability
		EnableControls
		switch($_.Node.Name){
			"pubFolMigNode"{Write-Host "Public Folder Migration"}
			"migPubFolNode"{$Global:currentDisplay="pubFolNode";SetFilter;GetMigPubFolTabControl}
			"verMigNode"{Write-Host "Verify Migration"}
			"rolBacMigNode"{Write-Host "Role Back Migration"}
			"pubFolTooNode"{Write-Host "Public Folder Tools"}
			"pubFolNode"{$Global:currentDisplay="pubFolNode";SetFilter;GetPubFolNodeTree}
			"pubFolDatNode"{$Global:currentDisplay="pubFolDatNode";GetPubFolDatDataGridView}
			"pubFolMaiNode"{$Global:currentDisplay="pubFolMaiNode";SetFilter;GetPubFolMaiDataGridView}
		}
	})
	#endregion actionTreeView Handlers

#region test
#GetPreviousMigrations
#$Global:curVersion=2013
#endregion test

	SetObjectAvailability
	$InitialFormWindowState = $pfmtForm.WindowState
	$pfmtForm.add_Shown({
		if(!((Test-Path HKLM:\SOFTWARE\Microsoft\ExchangeServer\v14\Setup) -and (Test-Path ((get-itemproperty HKLM:\SOFTWARE\Microsoft\ExchangeServer\v14\Setup).MsiInstallPath + "bin\RemoteExchange.ps1")))){
			PopUp "`r`nYou must have the Exchange 2010 Management Tools`r`ninstalled in order to run this program." -Fatal
		}
	})
	$pfmtForm.add_Closing({Stop-Transcript|Out-Null})
	$pfmtForm.ShowDialog()| Out-Null
}

CheckSTA
ExpandBin
SetUpGlobalVariables
GenerateForm
