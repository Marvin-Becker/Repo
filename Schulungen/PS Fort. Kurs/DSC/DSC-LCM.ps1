[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node srv2
    {
        Settings
        {
	ConfigurationMode = "ApplyAndAutoCorrect"	
        }
    }
}
LCMconfig


Set-DscLocalConfigurationManager -Path C:\LCM\LCMConfig


# �nderung auf "ApplyAndAutoCorrect" sonst ("ApplyAndMonitor") nur einmalige Anwendung und dann �berwachung des Status