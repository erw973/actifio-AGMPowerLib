Function Get-AGMLibImageRange([int]$appid,[string]$jobclass,[string]$appname,[int]$clusterid,[string]$appliancename,[string]$apptype,[string]$fuzzyappname,[datetime]$consistencydate,[int]$newerlimit,[int]$olderlimit,[switch][alias("h")]$hours) 
{
    <#
    .SYNOPSIS
    Displays the range of images for an application or applications

    .EXAMPLE
    Get-AGMLibImageRange
    You will be prompted to supply either application ID, Appname or fuzzyappname.   In addition or in place you can specify apptype
    If no newerlimit or olderlimit are specified then it defaults to -olderlimit 1 days
    If no consistencydate is specified todays date and time is assumed

    .EXAMPLE
    Get-AGMLibImageRange -appid 4771
    Get all snapshot created in the last day for appid 4771
    
    .EXAMPLE
    Get-AGMLibImageRange -appname smalldb
    Get all snapshot created in the last day for any app with app name smalldb

    .EXAMPLE
    Get-AGMLibImageRange -fuzzyappname smalldb
    Get all snapshot created in the last day for any app with an app name like smalldb

    .EXAMPLE
    Get-AGMLibImageRange -appid 4771 -appliancename "sa-hq"
    Get all snapshot created in the last day for appid 4771 on the appliance called sa-hq

    .EXAMPLE
    Get-AGMLibImageRange -appid 4771 -clusterid 1415038912
    Get all snapshot created in the last day for appid 4771 on the appliance with the specified clusterid

    .EXAMPLE
    Get-AGMLibImageRange -appid 4771 -jobclass dedup
    Get all dedups created in the last day for appid 4771

    .EXAMPLE
    Get-AGMLibImageRange -appid 4771 -olderlimit 4 -hours
    Get all snapshots created in the last four hours for appid 4771

    .EXAMPLE
    Get-AGMLibImageRange -apptype VMBackup -olderlimit 2
    Get all snapshots created in the last two days for any VMBackup

    .EXAMPLE
    Get-AGMLibImageRange -appid 4771 -olderlimit -newerlimit 4 -consistencydate "2020-08-04 12:00"
    Get all snapshots created up to four days before or 4 days afer the date specified for the app specified

    .DESCRIPTION
    A function to find a range of images available for an application
    
    #>

    if ( (!($AGMSESSIONID)) -or (!($AGMIP)) )
    {
        Get-AGMErrorMessage -messagetoprint "Not logged in or session expired. Please login using Connect-AGM"
        return
    }
    
    if ($appid)
    { 
        $fv = "appid=$appid"
    }
    elseif ($appname)
    {
        $fv = "appname=" + $appname
    }
    elseif ($fuzzyappname)
    {
        $fv = "appname~" + $fuzzyappname
    }

    if ( (!($fv)) -and ($apptype) )
    {
        $fv = "apptype=" + $apptype
    }
    elseif ( ($fv) -and ($apptype) )
    {
        $fv = $fv + "&apptype=" + $apptype
    }
 
    if (!($fv))
    { 
        Get-AGMErrorMessage -messagetoprint "Please specify either appid, appname, fuzzyappname or apptype."
        return
    }

      
    if ($jobclass)
    {
        $fv = $fv + "&jobclass=$jobclass"
    }
    else 
    {
        $fv = $fv + "&jobclass=snapshot"
    }

    if ($appliancename)
    { 
        $clusterid = (Get-AGMAppliance -filtervalue name=$appliancename).clusterid
        if (!($clusterid))
        {
            Get-AGMErrorMessage -messagetoprint "Could not convert appliancename $appliancename into a clusterid."
            return
        }
    }


    if ($clusterid)
    {
        $fv = $fv + "&clusterid=$clusterid"
    }



    if ( (!($newerlimit)) -and (!($olderlimit)) )
    {
        $lowerlimit = -1
        if (!($consistencydate))
        {
            $consistencydate = (Get-date).AddMinutes(1).ToString('yyyy-MM-dd HH:mm:ss')
        }
        if ($hours)
        { 
            $lowerrange = (Get-date).Addhours(-1).ToString('yyyy-MM-dd HH:mm:ss')
        }
        else 
        {
            $lowerrange = (Get-date).adddays(-1).ToString('yyyy-MM-dd HH:mm:ss')
        }
        $fv = $fv + "&consistencydate>$lowerrange"
    }
    elseif ( ($newerlimit) -and (!($olderlimit)) )
    {
        if (!($consistencydate))
        {
            Get-AGMErrorMessage -messagetoprint "A newerlimit was specified without a consistency date in the past to search forward from."
            return
        }
        $lowerrange = $consistencydate.ToString('yyyy-MM-dd HH:mm:ss')
        if ($hours)
        { 
            $upperrange = ($consistencydate).Addhours($newerlimit).ToString('yyyy-MM-dd HH:mm:ss')
        }
        else 
        {
            $upperrange = ($consistencydate).adddays($newerlimit).ToString('yyyy-MM-dd HH:mm:ss')
        }
        $fv = $fv + "&consistencydate>$lowerrange&consistencydate<$upperrange"
    }
    elseif ( (!($newerlimit)) -and ($olderlimit) )
    {
        if (!($consistencydate))
        {
            $consistencydate = (Get-date).AddMinutes(1).ToString('yyyy-MM-dd HH:mm:ss')
        }
        $upperrange = $consistencydate.ToString('yyyy-MM-dd HH:mm:ss')
        if ($hours)
        { 
            $lowerrange = ($consistencydate).Addhours(-$olderlimit).ToString('yyyy-MM-dd HH:mm:ss')
        }
        else 
        {
            $lowerrange = ($consistencydate).adddays(-$olderlimit).ToString('yyyy-MM-dd HH:mm:ss')
        }
        $fv = $fv + "&consistencydate>$lowerrange&consistencydate<$upperrange"
    }
    else 
    {
        if (!($consistencydate))
        {
            $consistencydate = (Get-date).AddMinutes(1).ToString('yyyy-MM-dd HH:mm:ss')
        }
        if ($hours)
        { 
            $upperrange = ($consistencydate).Addhours($newerlimit).ToString('yyyy-MM-dd HH:mm:ss')
        }
        else 
        {
            $upperrange = ($consistencydate).adddays($newerlimit).ToString('yyyy-MM-dd HH:mm:ss')
        }
        if ($hours)
        { 
            $lowerrange = ($consistencydate).Addhours(-$olderlimit).ToString('yyyy-MM-dd HH:mm:ss')
        }
        else 
        {
            $lowerrange = ($consistencydate).adddays(-$olderlimit).ToString('yyyy-MM-dd HH:mm:ss')
        }
        $fv = $fv + "&consistencydate>$lowerrange&consistencydate<$upperrange"
    }


    $output = Get-AGMImage -filtervalue "$fv" -sort ConsistencyDate:desc
    if ($output.id)
    {
        $AGMArray = @()

        Foreach ($id in $output)
        { 
            $id | Add-Member -NotePropertyName appid -NotePropertyValue $id.application.id
            $id | Add-Member -NotePropertyName appliancename -NotePropertyValue $id.cluster.name
            $id | Add-Member -NotePropertyName hostname -NotePropertyValue $id.host.hostname
            $AGMArray += [pscustomobject]@{
                apptype = $id.apptype
                hostname = $id.hostname
                appname = $id.appname
                appid = $id.appid
                appliancename = $id.appliancename
                jobclass = $id.jobclass
                backupname = $id.backupname
                id = $id.id
                consistencydate = $id.consistencydate
                endpit = $id.endpit

            }
        }
        $AGMArray | select apptype, appliancename, hostname, appname, appid, jobclass, backupname, id, consistencydate, endpit | Sort-Object -Property appliancename,hostname
    }
    else
    {
        $output
    }




}