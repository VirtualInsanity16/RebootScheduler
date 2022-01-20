#######################################################################################################################
 #Created by AKB on 3/11/2020  Updated on 4/9                                                                                        #
                                                                                                                #
 #This Script checks for uptime. If over 48 hours it asks the user to reboot.                                          #
 #If the user opts not to reboot it creates a schedule task and a powershell script to reboot after X amount of hours  #
 #######################################################################################################################
 
 #this part of the script checks for files and the schtasks 
 #that are created later in the script and deletes them if they exist

 $path = Test-Path "C:\\scheduler.ps1"
 $schtask = Get-ScheduledTask -TaskName "RebootSchedulerv2" 

 If($path -eq $true) {

        Remove-Item "C:\\scheduler.ps1" -ErrorAction SilentlyContinue
 }

 If($schtask.TaskName -match 'RebootSchedulerv2' ){
        Unregister-ScheduledTask -TaskName $schtask.taskname -Confirm:$false -ErrorAction SilentlyContinue
}


 #This creates the cmdlet for get-uptime and out-puts it into a dec number

 function Get-Uptime {
   $os = Get-WmiObject win32_operatingsystem
   $uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
   $display = $uptime.totalhours
   Write-Output $display
   }
   
  $x = Get-Uptime
  $z = [math]::Round($x)

  If($x -ge '2.0'){

  #This creates the dialouge box with our options for yes and no and depending on the selection creates a reboot task. 

  Add-Type -AssemblyName System.Windows.Forms

     

  $msgbox1 = [System.Windows.Forms.MessageBox]::Show("Your Computer Has Not Been Shutdown In Over $z Hours.  Would you like to reboot now?
 Press 'Yes' to reboot now or press 'No' to delay reboot until 2 A.M.","REBOOT SCHEDULER","YesNo")
  
   Switch ($msgbox1) {

   'Yes' {
   shutdown -r -t 01

   }
   
   'No' {
   
   $date = Get-Date
   $reboottime = $x - '02:00'


   #This writes out the powershell script that creates the 5min warning and issues the reboot command

   'Add-Type -AssemblyName System.Windows.Forms 
   $msgbox2 = [System.Windows.Forms.MessageBox]::Show("Your Computer will shutdown in 5 minutes Please save your work.","REBOOT SCHEDULER","OK")
   shutdown -r -t 300'| Out-File "C:\\scheduler.ps1" -ErrorAction Ignore
      
   #this creates the schedule task to run the powershell command at the end of the 12 hour delay
   #This will also ignore the task if its already created


   $params = @{
        Day = $date.AddDays(1).Day
        Hour = 2
        Minute = 0
        Second = 0
        }
        $triggertime = Get-Date @params
        
 $action = New-ScheduledTaskAction -Execute "powershell.exe"  -Argument "-file C:\\scheduler.ps1" -ErrorAction SilentlyContinue
   $trigger = New-ScheduledTaskTrigger -Once -At $triggertime -ErrorAction SilentlyContinue
     $tskprin = New-ScheduledTaskPrincipal -UserId "LOCALSERVICE" -LogonType ServiceAccount -ErrorAction SilentlyContinue
       $sett = New-ScheduledTaskSettingsSet -ErrorAction SilentlyContinue
        $Task = New-ScheduledTask -Action $action -Principal $tskprin -Trigger $trigger -Settings $sett -ErrorAction SilentlyContinue

               Register-ScheduledTask RebootSchedulerv2 -InputObject $Task -ErrorAction Ignore

    

   }
   }
   }




  
