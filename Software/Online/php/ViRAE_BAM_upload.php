<?php
// Make HTML page
echo '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ViRAE Tool - Virus Genome RNA-seq Read Decontamination</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f7f7f7;
        }
        header {
            background-color: #007BFF;
            color: #fff;
            text-align: center;
            padding: 20px;
            position: relative; /* To position the logo */
        }
        .container {
            max-width: 800px;
            margin: 20px auto;
            padding: 20px;
            background-color: #fff;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        h1 {
            font-size: 24px;
        }
        h2 {
            font-size: 20px;
        }
        p {
            font-size: 16px;
        }
        .documentation-button,
        .contact-button {
            display: inline-block;
            background-color: #007BFF;
            color: #fff;
            padding: 10px 20px;
            text-decoration: none;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
        }
        .documentation-button:hover,
        .contact-button:hover {
            background-color: #0056b3;
        }
        .documentation-button + .contact-button {
            margin-left: 10px; /* Add space between buttons */
        }
        .logo {
            position: absolute;
            top: 10px;
            left: 10px;
        }
    </style>
</head>

<body>
    <header>
        <img src="DUTH_logo.png" alt="Democritus University of Thrace Logo" class="logo">
        <h1>ViRAE - Virus Genome RNA-seq Read Decontamination Tool</h1>
        <a href="http://github.com" class="documentation-button">Documentation</a>
        <a href="https://biology.med.duth.gr/" class="contact-button">Contact</a>
    </header>
    
	<div class="container">
        <p>Viral Reads Assembly Enhancer (VIRAE) is a context-based trimming bioinformatics tool, especially designed for viral metagenomics, which allows Next Generation Sequencing (NGS) read decontamination based on any given reference sequence(s). VIRAE is powered by an updated version of <a href="https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1009304">Zero-Waste Algorithm (ZWA)</a> and incorporates ready-to-use well-established bioinformatics software to detect and dissect partially mapped reads (chimeric reads) by specifically removing the moieties, which align to the given reference sequence(s). The clean output reads enhance de novo assembly performance, increasing the availability of reads for more accurate and more efficacious de novo virus genome assembly.</p>
    </div>
';

// Turn off output buffering
ini_set('output_buffering', 'off');
ini_set('zlib.output_compression', false);
ini_set('implicit_flush', true);
ob_implicit_flush(true);
ob_end_flush();
flush();

// Specify the upload and download directories
$uploadDir = "/usr/local/lsws/Example/html/ViRAE/FILE_STORAGE/ViRAE_uploads/";
$downloadDir = "/usr/local/lsws/Example/html/ViRAE/FILE_STORAGE/ViRAE_downloads/";

// SUBROUTINES
function uploadMethod($htmlParameter) {
    global $uploadDir, $downloadDir;

    // Check and modify the FileTransfer URL if needed
    if (isset($_FILES[$htmlParameter . "_dialog"])) {
        $uploadFile = $_FILES[$htmlParameter . "_dialog"];
        $uploadFilename = $uploadFile['name'];
        $uploadFilePath = $uploadDir . $uploadFilename;
        
        echo "<p>File $uploadFilename is being uploaded, please wait...</p>";
        flush();

        if (move_uploaded_file($uploadFile['tmp_name'], $uploadFilePath)) {
            return $uploadFilePath;
        } else {
            echo "<p>Error moving uploaded file.</p>";
        }
    } elseif (isset($_POST[$htmlParameter . "_link"])) {
        $uploadLink = $_POST[$htmlParameter . "_link"];
        
        if (strpos($uploadLink, 'https://filetransfer.io/') === 0) {
            $uploadLink = preg_replace("/#link$/", "/download", $uploadLink);
            
            if (!preg_match("/\/download$/", $uploadLink)) {
                $uploadLink .= "/download";
            }

            // Extract the filename from the 'Content-Disposition' header
            $headers = get_headers($uploadLink, 1);
            $contentDisposition = $headers['Content-Disposition'];

            if (isset($contentDisposition)) {
                preg_match('/filename="([^"]+)"/', $contentDisposition, $filenameMatch);
                $uploadFilename = $filenameMatch[1];

                // Save the downloaded content to a local file usin aria2c
                $uploadFilePath = $uploadDir . $uploadFilename;
                echo "<p>File $uploadFilename is being uploaded, please wait...</p>";
                shell_exec("aria2c -s 16 -x 16 -d $uploadDir $uploadLink");
                flush();

                if (file_exists($uploadFilePath)) {
                    return $uploadFilePath;
                } else {
                    echo "<p>Error saving downloaded file.</p>";
                }
            } else {
                echo "<p>Link has probably expired.</p>";
            }
        } else {
            echo "<p style='color: red;'>Invalid FileTransfer URL</p>";
        }
    } else {
        echo "<p style='color: red;'>Failed to upload file</p>";
    }
    
    flush();
}

function checkFileFormat($file_path) {
    $file_extension = pathinfo($file_path, PATHINFO_EXTENSION);
    $header = '';

    if ($file_extension === 'bam') {
        $file_handle = fopen($file_path, 'rb');
        if ($file_handle !== false) {
            // Read the first 4 bytes from the file
            $header = fread($file_handle, 4);
            fclose($file_handle);
        }
    }

    // Check if the first four bytes match the BAM magic number
    if ($header === "\x1F\x8B\x08\x04") {
        $bam_stats = shell_exec("samtools flagstat $file_path");
        echo "<p>Upload successful! BAM file statistics</p>";
        echo "<pre>$bam_stats</pre>";
        flush();
    } else {
        echo "<p style='color: red;'>Invalid BAM formatted file</p>";

        if (file_exists($file_path)) {
            unlink($file_path);  // Check if the file exists and remove it
        }
    }
}

function run_virae($file_path, $output_dir) {
    echo "<h1>ViRAE execution result</h1>";
    echo "<p>Running ViRAE now, please wait...</p>";
    flush();

    $command = "/home/inseqt/COSTAS_CON/TOOLS/SCRIPTS/ViRAE.sh -m $file_path -o $output_dir ";
    $output = shell_exec($command);

    echo "<pre>$output</pre>";
    flush();
}

function download_virae_files($file_path) {
    global $downloadDir;

    $file_info = pathinfo($file_path);
    $file_name = $file_info['filename'];
    $file_extension = pathinfo($file_path, PATHINFO_EXTENSION);

    $downloadFileDir = "ViRAE-" . $file_name;

    #shell_exec("cd $downloadDir ; tar -czvf ViRAE-$file_name.tar.gz $downloadFileDir && rm -rf $downloadFileDir ");
    shell_exec("cd $downloadDir ; zip -r ViRAE-$file_name.zip $downloadFileDir && rm -rf $downloadFileDir ");
    $downloadFileName = "ViRAE-" . $file_name . ".zip";

    echo "<p><a href='https://srv-inseqt.med.duth.gr/ViRAE/FILE_STORAGE/ViRAE_downloads/$downloadFileName' download='$downloadFileName'>Download ViRAE files</a></p>";
}

// MAIN
echo "<title>Upload Status</title>";
echo "<h1>Upload Status</h1>";
echo "<h2>BAM file</h2>";
flush();

$uploadBamFilePath = uploadMethod("bam_file");
checkFileFormat($uploadBamFilePath);
if (file_exists($uploadBamFilePath)) {
    run_virae($uploadBamFilePath, $downloadDir);
    download_virae_files($uploadBamFilePath);
} else {
    $errorMessage = "Invalid input BAM file! Click OK to be redirected to the ViRAE file upload page.";
    
    echo "<script>alert('$errorMessage');</script>";
    echo "<meta http-equiv='refresh' content='1;url=https://srv-inseqt.med.duth.gr/ViRAE/HTML/ViRAE_BAM_upload.html'>";
}
?>
