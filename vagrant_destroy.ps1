vagrant global-status | Select-String -Pattern 'name' -Context 2 | ForEach-Object { $Id = (($_.Context.PostContext[1] -replace 'Win.*')).trim() }
vagrant destroy $Id -f