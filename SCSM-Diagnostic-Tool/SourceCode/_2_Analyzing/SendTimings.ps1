function SendTimings() {

    [string]$minData = "msec,info`n"

    #Collector
    $rawData = GetFileContentInSourceFolder Collector-MeasuredScriptBlocks.csv | ConvertFrom-Csv
    foreach($line in $rawData) {        
        $msec = [timespan]::Parse($line.Duration).TotalMilliseconds
        $info = $line.ScriptBlockText
        $minData += "$msec,$info`n"
    }

    #Analyzer
    $rawData = GetFileContentInTargetFolder Analyzer-MeasuredScriptBlocks.csv | ConvertFrom-Csv
    foreach($line in $rawData) {        
        $msec = [timespan]::Parse($line.Duration).TotalMilliseconds
        $info = $line.ScriptBlockText
        $minData += "$msec,$info`n"
    }

 #Compression can be used if total response exceeds 200,000 characters bcz of MS forms limitation

    #Compress and then convert to base64
    $ms = New-Object System.IO.MemoryStream
    $cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
    $sw = New-Object System.IO.StreamWriter($cs)
    $sw.Write($minData)
    $sw.Close();
    $minData = [System.Convert]::ToBase64String($ms.ToArray())

<#
    #convert compressed base64 to decompressed utf8 string
    $base64String = 'H4...AAA=='
    [byte[]]$byteArray = [System.Convert]::FromBase64String($base64String)
    $input = New-Object System.IO.MemoryStream( , $byteArray )
    $output = New-Object System.IO.MemoryStream
    $gzipStream = New-Object System.IO.Compression.GzipStream $input, ([IO.Compression.CompressionMode]::Decompress)
    $gzipStream.CopyTo( $output )
    $gzipStream.Close()
    $input.Close()
    $decompressedByteArray = $output.ToArray()
    $originalDecompressedString = [System.Text.Encoding]::UTF8.GetString($decompressedByteArray)
#>

    #Split into 4000 character parts per Question bcz of MS forms limitation
    $bodyStart ='{"answers":"['
    $startPos = 0
    $questionIDs = "r14f509ca5b734d3f9ed292e42acb011a","rf9b227915ae54f8d93d0206ee3210fa4","rd84c67987a6b46d1a9a63e5cc6511673","r75eaa58db25f4de992382ccbd5ae8d29","rf2e073ae17de40c2acfc126df96a6f12","rad0902e642e642e7adfa57d356af4a0a","r680f515af201463ebc6d6351d8b0f4f6","r3b0a6b63bc0641539ac6e09ac0ca0261","rc0adee71a32a4df0a5e6a4860e298372","r9a610a66fbb4403198599304ef9672dd","ra2d31dc706404b89971f6e4fdeec1660","rcd7ef7efecbe44309604c220eaf764ae","r681b9195ebd747678afc91ba1fca550a","r2a5259256bd747aca01c0ef97dcb4f89","r54744977d244425c980bcce9f9c4815e","r32cda0df62b240559e4549de6001a5fd","r341435b595bf4a73bd9aeb5f02f6f4c9","rec80bae2f680412984105a1653a395be","rf940f378876c46f88f6369fa744c6d24","rb11cda7c23124ed1a84825b2b639cdc5","r6aaf378ae130414ca9b82e0b962d4091","r20e2d35ffb764da1bc6ea57ce6c719bb","r50ad1aefa9e44974b3e68e4d37a52c82","r2365651122d34739ab89c206cab694b1","r61df2ecc323943d2a66ce4102e1e2589","r8dfc22761f1d4242ba0707a6ba99616d","r28eb66652ac445548895d9e71f385026","rd3ba560f279746568328659639264146","rde2045a22ca0481fb9f3fcda5f0f0e71","r80f495dc4fa44bdabbbc81007f7ae8f5","r4a61a52cfccd4ca084fb2bb43b303ba6","r1276cf9ab0734434a761e86ca42cdb1e","ra8c8729ffe3a4c38a9c61b746a70f8a5","r30c1f9fccf034e919fdea48b2ceedd89","r0802c6d952014ea29d80a2cc52ac6515","r36dcbfd13526475db4795664a34998f4","r30c43540200e4f88b5af94b5a73aa2bd","r70b8ea90a49949e8b8fe19cca077e94c","r7458f57b4713469fa0482f83489a0734","raec9bf88600c4b9dbda88f954856b137","raff6e5fcee1c45ed8485bdadb6cfaf6f","r3df52174834e40fb9676a147aebbbfeb","rcd0a646ec5f6455b89c9d946b3be8170","r954183c1808a4de9966bfc18b32d6cf2","rcd3d2c99be7642f092bd78bb2c03cd1c","r75e14134a3b944289262907f063bac48","r31dcecd7d60a46e8b410990d357c814f","r3c42754a21aa4cd2981daeb73ca398ec","r6e04640a043e4e0f89ac03a2f43c5c67","r0d4cfd7cdc7f44f3a377558fb9195a54"
    $answers = ""
    $isFirst = $true
    foreach($questionID in $questionIDs) {
        $subStringLength = 4000
        if ($startPos + $subStringLength -gt $minData.Length) { 
            if ($startPos -gt $minData.Length) {
                $answer = ""
            }
            else {
                $answer = $minData.Substring($startPos)
            }
        }
        else {
            $answer = $minData.Substring($startPos, $subStringLength)
        }
        if ($isFirst) { $isFirst = $false } else { $answers += "," }
        $answers += "{\`"questionId\`":\`"$questionID\`",\`"answer1\`":\`"$answer\`"}"
        $startPos += 4000
    }    
    $bodyEnd = ']"}'
    $body =  "$bodyStart$answers$bodyEnd"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
    $uri = "https://forms.office.com/formapi/api/72f988bf-86f1-41af-91ab-2d7cd011db47/users/613ddf6e-fb7a-458e-b2da-f8a80fdeaf92/forms('v4j5cvGGr0GRqy180BHbR27fPWF6-45Fstr4qA_er5JUOUhCQUNSQlNFMURRSkg2WjRMWEZEVzA1Ty4u')/responses"
    Invoke-RestMethod -Method Post -Uri $uri -UseBasicParsing -ContentType "application/json" -Body $body -UseDefaultCredentials | Out-Null
    
}