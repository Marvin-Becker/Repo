configuration Test
{
  node ("Srv2","Srv3")
   {
     WindowsFeature MeineRollen
        {
           Ensure = "Absent"
           Name   = "XPS-Viewer"
        }

        File KonfigDaten
        {
            Ensure          = "Present"
            SourcePath      = "\\DC\Netlogon"
            Recurse = $true
            DestinationPath = "c:\Test"
            Type            = "Directory"
                    }       
    }
}

Test 