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


# Änderung auf "ApplyAndAutoCorrect" sonst ("ApplyAndMonitor") nur einmalige Anwendung und dann Überwachung des Status