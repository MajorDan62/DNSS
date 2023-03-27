######################	
# RESOLVE DNS HOSTS  #
# DATED 24-03-2023   #
# DESIGNER MA JORDAN #
######################
clear
$cr="`r`n"
$_data_file = 	"./datalist.txt" 
$_clipflag	=	$True
$_display 	=	$false
$_RDNS		=	$false
$_resolve	=	$false
#############
# FUNCTIONS #
#############
function find_domain_ISP($ip)
{	
	Invoke-WebRequest -uri "https://www.abuseipdb.com/check/$ip" -outfile "temp.txt"
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
	if ($linenumber -gt 0 ){$abuse="ABUSE LOGGED"}else{$abuse="NO ABUSE LOGGED"}

    $result			=	$cr + "  ISP    = $result "+ $cr + "  DN     = " + $domain + $cr +  "  LOC    = " + $country +  $cr +  "  STATUS = " + $abuse +$cr
    return $result
}

if ($args.count -gt 0)
{
	for ($i=0;$i -lt $args.count;$i++)
	{
        if ($args[$i] -eq $null)		{$_display		=	$True}
		if ($args[$i] -eq "-v")			{$_display		=	$True}
		if ($args[$i] -eq "-noclip")	{$_clipflag		=	$False}
		if ($args[$i] -eq "-in")		{$_data_file	=	"./"+$args[($i+1)]}
		if ($args[$i] -eq "-R")			{$_RDNS			=	$True}
        if ($args[$i] -eq "-P")			{$_resolve		=	$True}
	}
}
else {$_display=$True} 

if ($_display)
{
	write-host "===================================="
	write-host "| Name    : DNS Name Resolution    |"
	write-host "| Version : 20230324_v1            |"
	write-host "| Dated   : 23th March 2023        |"
	write-host "| Author  : " -nonewline
	write-host -f green "Mike Jordan" -nonewline
	write-host -f white "            |"
	write-host "===================================="
	write-host " -v       Display this screen (Help)"
	write-host " -in      Select data source"
	write-host " -noclip  No copy to Clipboard"
	write-host " -R       Use Reverse DNS Search"
	write-host " -P       Find the Domain Owner in Public"
	write-host -f red "          **REQUIRES INTERNET CONNECTION**"
	write-host
	exit
}
$output=""
$data = Get-Content $_data_file
	
if (!$_RDNS)
{
	write-host -b green -f white "-- DNS LOOKUP --"
	write-host
	foreach ($line in $data)
	{			
		$line=$line.replace(" ","")
		if ($line[0] -ne "#")
		{
			try
			{
				$result=Resolve-DnsName $line 
			}
			catch 
			{
				if ($line[0] -gt $null)
				{Write-Host -b red -f black " '$line' DNS Lookup Failed "}
				$failed=$True
			}
			
			if (!$failed)
			{
				$count=0
				if ($result.count -gt 1)
					{
					$_output=""
					do
						{
							$output= $result[$count].name + " - " + $result[$count].ipaddress + " **DUPLICATE**"
							write-host $output
							$_output= $_output+ $result[$count].name + " - " + $result[$count].ipaddress + " **DUPLICATE**"+$cr
							$count=$count + 1
						}	
					while ($result.count -gt $count )
					$output=$_output
					}
					else
						{
							$output= $result.name + " - " + $result.ipaddress
							write-host $output
						}
					$summary=$summary+$output+$cr
					}
				}
			}
		if ($_clipflag){$summary  -replace "`r`n`r`n", "`r`n"| sort | clip}else{Set-Clipboard -Value $null}
	}
	
	elseif ($_RDNS)
	{
		write-host -b red -f white " -- REVERSE DNS LOOKUP  -- "
		if ($_resolve)
			{
				$conn=(Test-Connection -ComputerName google.com -Count 1 -Quiet)
				if ($conn)
				{  
					write-host -b red -f white " --  LOCATING RECORDS   -- "
				}
				else 
				{
					write-host -b red -f white " - NO PUBLIC CONNECTION - "
					$_display=$false
				}
			}

		write-host
		foreach ($line in $data)
		{

			if ($line[0] -ne "#" -and  $line.length -gt 1)
			{
				$failed=$false
				try
				{
					$result		=	[system.net.dns]::gethostentry($line)
					$failed		=	$false
				}
				catch 
				{
					if ($line[0] -gt $null)
					{Write-Host -b red -f black " '$line' Reserve DNS Lookup Failed "}
					$result=$line
					$failed=$True
				}
			
				if (!$failed)
				{
					$count=0
					if ($result.count -gt 1)
						{
						$_output=""
						do
							{			
								$output		= $result[$count].name + " - " + $result[$count].ipaddress + " **DUPLICATE**"
								write-host $output
								$_output	= $_output+ $result[$count].hostname + " - " + $result[$count].ipaddress + " **DUPLICATE**"

								if ($_resolve)
								{
										$_ip_		=	$result[$count].ipaddress
										$_rv_		=	find_domain_ISP($_ip_)f
										$_output	= 	$_ip_ + " resolves to "+ $_output + " - " + $_rv_
								}
								$_output	=   $_output+$cr
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
									$output		= 	 $output +  $_rv_
							}
							write-host $output 
						}
						$summary=$summary+$output+$cr
					}
				}
			}
		if ($_clipflag){$summary  -replace "`r`n`r`n", "`r`n"| sort | clip}else{Set-Clipboard -Value $null}
		}
	write-host