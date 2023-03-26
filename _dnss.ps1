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
$_RDNS=$false
if ($args.count -gt 0)
{
	for ($i=0;$i -lt $args.count;$i++)
	{
			if ($args[$i] -eq "-v")			{$_display=$True}
			if ($args[$i] -eq "-noclip")	{$_clipflag=$False}
			if ($args[$i] -eq "-in")		{$_data_file="./"+$args[($i+1)]}
			if ($args[$i] -eq "-R")			{$_RDNS=$True}
            if ($args[$i] -eq "")			{$_display=$True}
	}
} 

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
	write-host " -in      Select data source"
	write-host " -noclip  No copy to Clipboard"
	write-host " -R       Use Reverse DNS Search"
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
			$failed=$false
			try
			{
				$result=Resolve-DnsName $line -ErrorAction Stop
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
		write-host -b red -f white "-- REVERSE DNS LOOKUP --"
		write-host
		foreach ($line in $data)
		{
			$line=$line.replace(" ","")
			if ($line[0] -ne "#")
			{
	
				$failed=$false
				try
				{
					$result= [system.net.dns]::gethostentry($line)
				}
				catch 
				{
					if ($line[0] -gt $null)
					{Write-Host -b red -f black " '$line' Reserve DNS Lookup Failed "}
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
								$_output= $_output+ $result[$count].hostname + " - " + $result[$count].ipaddress + " **DUPLICATE**"+$cr
								$count=$count + 1
							}	
						while ($result.count -gt $count )
						$output=$_output
						}
						else
						{
							$output= $result.hostname + " - " + $result.addresslist
							write-host $output
						}
						$summary=$summary+$output+$cr
					}
				}
			}
		if ($_clipflag){$summary  -replace "`r`n`r`n", "`r`n"| sort | clip}else{Set-Clipboard -Value $null}
		}