######################	
# RESOLVE DNS HOSTS  #
# VERSION 1_230324	 #
# DATED 24-03-2023   #
# DESIGNER MA JORDAN #
######################
# VERSION 1.1_230403 #
# CATCH NULL MEMORY  #
######################
# VERSION 1.2_230403 #
# VALIDATE IP & URL  #
######################
# VERSION 1.3_230427 #
# ADD OUTPUT CODE    #
# ADD REBOOT CODE    #
######################
clear
$cr="`r`n"
$_data_file 			= 	"./datalist.txt" 
$_date 				= 	Get-Date -format yyyyMMdd_HH_mm
$_output_file_	 		= 	".\output_" + $_date  +".txt" 
$_clipflag			=	$True
$_display 			=	$false
$_RDNS				=	$false
$_resolve			=	$false
$_AbuselPBD 			=	$false
$_input_file_			=	$false
$_output_file			=	$false
$_ignore			=	$true
$_stealth			=	$false

#############
# FUNCTIONS #
#############

function validate_ip($ip){if ([BOOL]($ip -as [IPADDRESS])){return $true} else {return $false}}

function validate_url($url)
{
	#This is the regex pattern you can use to validate the format - reference : https://www.regextester.com/94502
	$regEx="^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$"
	if($url -match $regEx){return $true}else {return $false}
}

function Last_reboot(){return  (gcim Win32_OperatingSystem).LastBootUpTime} 

function find_domain_ISP($ip)
{	
	$_url_="https://www.abuseipdb.com/check/$ip" 
	Invoke-WebRequest -uri $_url_ -outfile "temp.txt"
	$linenumber		=	( select-string -path temp.txt  -pattern "<th>ISP</th>").linenumber
	$x				=	($linenumber + 1)
    $result			=	Get-Content "temp.txt "| Select-Object  -Skip $x  -First 1

	$linenumber		=	( select-string -path temp.txt  -pattern "<th>Domain Name</th>").linenumber
	$x				=	($linenumber + 1)	
	$domain			=	Get-Content "temp.txt "| Select-Object  -Skip ($x)  -First 1

	$linenumber		=	( select-string -path temp.txt  -pattern "<th>Country</th>").linenumber
	$x				=	($linenumber + 1)	
	$country		=	Get-Content "temp.txt "| Select-Object  -Skip ($x+1)  -First 1

	$linenumber		=	( select-string -path temp.txt  -pattern "was found in our database!").linenumber
	if ($linenumber -gt 0 )
		{
			if ($_AbuselPBD)
			{
				[system.Diagnostics.Process]::Start("msedge",$_url_)
			}

			$linenumber	=	( select-string -path temp.txt  -pattern "progress-bar").linenumber
			$rating		=	Get-Content "temp.txt "| Select-Object  -Skip ($linenumber)  -First 1
			$rating=$rating.replace("<span>","")
			$rating=$rating.replace("</span>","")
			$abuse="ABUSE LOGGED, Confidence of Abuse is $rating" 
		}
		else{$abuse="NO ABUSE LOGGED"}

    	$result			= $cr+"  ISP    = $result "+ $cr + "  DN     = " + $domain + $cr +  "  LOC    = " + $country +  $cr +  "  STATUS = " + $abuse + $cr
    return $result
}

$_lr_	=	last_reboot
if ($args.count -gt 0)
{
	for ($i=0;$i -lt $args.count;$i++)
	{
        if ($args[$i] -eq $null)					{$_display		=	$True}
		if ($args[$i].ToUpper() -eq "-V")			{$_display		=	$True}
		if ($args[$i].ToUpper() -eq "-NOCLIP")		{$_clipflag		=	$False}
		if ($args[$i].ToUpper() -eq "-IN")			{$_data_file	=	"./"+$args[($i+1)];$_input_file_=$true}
		if ($args[$i].ToUpper() -eq "-OUT")			{$_output_file	=	$true}
		if ($args[$i].ToUpper() -eq "-R")			{$_RDNS			=	$True}
        	if ($args[$i].ToUpper() -eq "-P")			{$_resolve		=	$True}
    		if ($args[$i].Toupper() -eq "-LAUNCH")		{$_AbuselPBD	=	$True}
    		if ($args[$i].Toupper() -eq "-L")			{$_AbuselPBD	=	$True}
   		if ($args[$i].Toupper() -eq "-MEM")			{$_mem			=	$True}
  		if ($args[$i].Toupper() -eq "-I")			{$_ignore		=	$false}
 		if ($args[$i].Toupper() -eq "-Q")			{$_stealth		=	$true}
	}
}
else {$_display=$True} 

if ($_display)
{
	write-host "===================================="
	write-host "| Name    : DNS Name Resolution    |"
	write-host "| Version : 20230425_v2            |"
	write-host "| Dated   : 23th March 2023        |"
	write-host "| Author  : " -nonewline
	write-host -f green "Mike Jordan" -nonewline
	write-host -f white "            |"
	# write-host "| Last Reboot $_lr_  |"
	write-host "===================================="


	write-host " -i       Filter out failed attempts"
	write-host " -q       No Dispalay to Screen [Stealth Mode]"
	write-host " -in      Select data input source"
	write-host -f green "          Leave this blank to use 'datalist.txt'"
	write-host " -l       Open 'https://www.abuseipdb.com/check' "
	write-host " -mem     Use the Clipboard contents"
	write-host " -noclip  No save results to Clipboard"
	write-host " -r       Use Reverse DNS Search"
	write-host " -p       Find the Domain Owner in Public"
	write-host -f red "          **REQUIRES INTERNET CONNECTION**"
	write-host " -out     Select data output filename "
	write-host -f green "          file format 'OUTPUT_<DATE>_<TIME>.TXT'"

	write-host " -v       Display this screen (Help)"
	write-host
	exit
}
$output=""
$genesis = Get-Date

if (!$_mem)
{

	if ($_input_file_)
		{if (Test-Path $_data_file -PathType Leaf){}else{write-host -f white -b red  " ** ERROR: NO  DATAFILE LOCATED !! ** $cr    Please retype a valid filename   ";exit}}
	else
		{write-host -f white -b red " ** ERROR: NO DATAFILE STATED !! ** $CR RUN .\_dnss -in <file> required or .\_dnss -mem <CLIPBOARD>  " ;exit}
		$data = (Get-Content $_data_file)
}	
else
{
	$data = Get-Clipboard
	if (!$data)
	{
		write-host  -f white -b red  " ** ERROR: NO DATA IN CLIPBOARD !! ** Please reattempt Cut & Paste ";exit
	}
	$data=$data.replace(" ","")
}
	
if (!$_RDNS)
{
	write-host -b green -f white "-- DNS LOOKUP --"
	if ($_stealth){write-host  -b green -f white   "- STEALTH MODE -"}
		$summary=$null
	foreach ($line in $data)
	{
		
		$line=$line.replace(" ","")

		if ($line[0] -ne "#")
		{
			try
			{
				$result=Resolve-DnsName $line  -type A -ErrorAction	SilentlyContinue
			}
			catch 
			{
				if ($line[0] -gt $null)
				{if ($_ignore){Write-Host -b red -f black " '$line' DNS Lookup Failed $cr"}}
				$failed=$True
			}
	
			
			if (!$failed)
			{
				$count=0
				if ($result.count -gt 0)
					{
						$_output=""
						do
						{
							if (($result[$count].ipaddress) -like "*.*" )
							{
								$output= $result[$count].name + " - " + $result[$count].ipaddress 
								if (!$_stealth){write-host $output}
								$_output= $_output + $output + $cr

							}
							$count=$count + 1
						}	
						while ($result.count -gt $count )

						$output=$_output
					}
					else
						{
							write-host -b red -f BLACK $line" - FAILED!"
						}
						$summary=$summary + $output 
					}
					
				}
			}
		if ($_clipflag){$summary  -replace "`r`n`r`n", "`r`n"| sort | clip}else{Set-Clipboard -Value $null}
		if ($_output_file){write-host "Output saved to "$_output_file_;$summary  | Out-File $_output_file_}
	}
	
	elseif ($_RDNS)
	{
		write-host -b red -f white " -- REVERSE DNS LOOKUP  -- "
		$summary=$null
		if ($_resolve)
			{
				$conn=(Test-Connection -ComputerName google.com -Count 1 -Quiet)
				if ($conn)
				{  
					write-host -b red -f white " --  LOCATING RECORDS   -- "
				}
				else 
				{
					write-host -b red -f white				 	" - NO PUBLIC  CONNECTION -"
					$_display=$false
				}	
			}
			if ($_stealth){write-host  -b blue -f white   	" ----- STEALTH MODE ------ "}
				write-host

		
		foreach ($line in $data)
		{
	
			if ($line[0] -ne "#" -and  $line.length -gt 1)
			{
				$line=$line -replace '(^\s+|\s+$)','' -replace '\s+',''
				$failed=$false
				if (validate_ip($line)){
				try
				{
					$result		=	[system.net.dns]::gethostentry($line)
					$failed		=	$false
				}
				catch 
				{
					if ($line[0] -gt $null)
					{if ($_ignore){Write-Host -b red -f black " '$line' Reverse DNS Lookup Failed "}}
					$result=$line
					$failed=$True
				}
			}	
			else
			{
				if ($_ignore){Write-Host -b red  -f black " IP Address '$line' format incorrect "}		
				$failed=$true
			}

			if ($failed) 
				{
					$output= $line + " unable to resolve"
					if ($_resolve)
					{
						$_ip_		=	$line 
						$_rv_		=	find_domain_ISP($_ip_)
						$output		= 	 $output +  $_rv_			
					}
		
					if (!$_stealth){write-host $output}
					$summary=$summary + $output + $cr
				}	
				elseif (!$failed)
				{
					$count=0
					if ($result.count -gt 1)
						{
						$_output=""
						do
							{			
								$output		= $result[$count].name + " - " + $result[$count].ipaddress + " **DUPLICATE**"
								if ($_stealth){write-host $output}
								$_output	= $_output+ $result[$count].hostname + " - " + $result[$count].ipaddress + " **DUPLICATE**"

								if ($_resolve)
								{
									$_ip_		=	$result[$count].ipaddress
									$_rv_		=	find_domain_ISP($_ip_)
									$_output	= 	$_ip_ + " resolves to "+ $_output + " - " + $_rv_

								}
								$_output	=   $_output + $cr
								$count=$count + 1
							}	
						while ($result.count -gt $count )
						
						$output=$_output
						}
						else
						{
							$output= $line + " resolves to " + $result.hostname 
							if ($_resolve)
							{
									$_ip_		=	$line 
									$_rv_		=	find_domain_ISP($_ip_)
									$output		= 	$output +  $_rv_
								
							}
								if (!$_stealth){write-host $output}
						}
						$summary=$summary + $output + $cr
					}
			}
			}
	
		if ($_clipflag){$summary  -replace "`r`n`r`n", "`r`n"| sort | clip}else{Set-Clipboard -Value $null}
		if ($_output_file)
			{
					write-host "Output saved to "$_output_file_;$summary  | Out-File $_output_file_
			}

		}
	$exodus=Get-Date
	write-host
	$delta=$exodus-$genesis;$h="{0:D2}" -f [int]$delta.hours;$m="{0:D2}" -f [int]$delta.minutes;$s="{0:D2}" -f [int]$delta.seconds
	write-host -b blue -f white " [_DNSS] Script Active for"$h"h "$m"m "$s"s ";
	write-host
