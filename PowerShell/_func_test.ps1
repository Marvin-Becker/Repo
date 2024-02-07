BEGIN {
    $ErrorCode = 0
    $Result = ''
    # einmaliger Aufruf, optional
    'Start'
    $ErrorCode = 1
    $Result += 'BEGIN. '
} 

#Aufruf mehrmals über Pipeline möglich
PROCESS {
    # if ( $Errorcode -ne 0) {
    #     $Result += 'Error'
    #     return $Result
    # }
    'Process'

    function Find-Tree {
        [CmdletBinding()]
        param ()

        $ErrorMessage = 'Error: AD-Anchor-Group not found. '
        
        if ($FullADPath) {
            $FullADPathArray = $FullADPath.Split( ',' , 2 )
            return $FullADPathArray[-1]
        } else {
            return $ErrorMessage # 'return' springt hier aus der Funktion
        }
    }

    $ADBaseOU = Find-Tree

    if ( $ADBaseOU -eq 'Error: AD-Anchor-Group not found. ') {
        $Result += 'Error: AD-Anchor-Group not found. '
        return $Result # 'return' springt direkt im Block ('PROCESS') immer zum nächsten Block (in diesem Fall 'END')
    }
}
# einmaliger Aufruf, optional
END {
    'End'
} 