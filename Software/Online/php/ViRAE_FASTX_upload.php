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
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

ini_set('output_buffering', 'off');
ini_set('zlib.output_compression', false);
ini_set('implicit_flush', true);
ob_implicit_flush(true);
ob_end_flush();
flush();

// Specify the upload and download directories
$uploadDir = "/usr/local/lsws/Example/html/ViRAE/FILE_STORAGE/ViRAE_uploads/";
$downloadDir = "/usr/local/lsws/Example/html/ViRAE/FILE_STORAGE/ViRAE_downloads/";

// Define upload method function
function upload_method($html_parameter, $uploadDir) {
    global $uploadDir;

    // Array to store uploaded file paths
    $uploadedFilePaths = [];

    // Check for file upload
    if (isset($_FILES[$html_parameter . "_dialog"])) {
        $uploadFiles = $_FILES[$html_parameter . "_dialog"];
        $dialogType = $html_parameter . "_dialog";

        // Normalize to ensure we always work with arrays
        if (!is_array($uploadFiles["name"])) {
            $uploadFiles["name"] = [$uploadFiles["name"]];
            $uploadFiles["type"] = [$uploadFiles["type"]];
            $uploadFiles["tmp_name"] = [$uploadFiles["tmp_name"]];
            $uploadFiles["error"] = [$uploadFiles["error"]];
            $uploadFiles["size"] = [$uploadFiles["size"]];
        }

        // Validate the number of files based on dialog type
        $numberOfFiles = count($uploadFiles["name"]);
        if ($dialogType == "reads_file_dialog" && $numberOfFiles > 2) {
            $errorMessage = "ERROR: You can upload up to 2 INPUT READS files only! Click OK to be redirected to the ViRAE file upload page.";

            echo "<script>alert('$errorMessage');</script>";
            echo "<meta http-equiv='refresh' content='1;url=https://srv-inseqt.med.duth.gr/ViRAE/HTML/ViRAE_FASTX_upload.html'>";
            die();
        } elseif ($dialogType == "ref_file_dialog" && $numberOfFiles > 1) {
            $errorMessage = "ERROR: You can upload up to 1 INPUT REF file only! Click OK to be redirected to the ViRAE file upload page.";

            echo "<script>alert('$errorMessage');</script>";
            echo "<meta http-equiv='refresh' content='1;url=https://srv-inseqt.med.duth.gr/ViRAE/HTML/ViRAE_FASTX_upload.html'>";
            die();
        }

        // Loop through and process uploads
        foreach ($uploadFiles["name"] as $index => $uploadFileName) {
            $uploadFilePath = $uploadDir . $uploadFileName;

            echo "<p>File $uploadFileName is being uploaded, please wait...</p>";
            flush();

            if (move_uploaded_file($uploadFiles["tmp_name"][$index], $uploadFilePath)) {
                echo "<p>File $uploadFileName has been successfully uploaded !!! </p>";
                if ($numberOfFiles == 2) {
                    $uploadedFilePaths[] = $uploadFilePath;
                } elseif ($dialogType == "reads_file_dialog" && $numberOfFiles == 1) {
                    $uploadedFilePaths = [$uploadFilePath];
                } elseif ($dialogType == "ref_file_dialog" && $numberOfFiles == 1) {
                    $uploadedFilePaths = $uploadFilePath;
                }
            } else {
                $errorMessage = "ERROR: File could not be uploaded! Click OK to be redirected to the ViRAE file upload page.";

                echo "<script>alert('$errorMessage');</script>";
                echo "<meta http-equiv='refresh' content='1;url=https://srv-inseqt.med.duth.gr/ViRAE/HTML/ViRAE_FASTX_upload.html'>";
                die();
            }
        }
    }
    // Check for SRA accession
    elseif (isset($_POST[$html_parameter . "_sra_accession"])) {
        $uploadSRAAccession = $_POST[$html_parameter . "_sra_accession"];

        echo "<p>Processing SRA accession $uploadSRAAccession, please wait...</p>";
        flush();

        // Define the SRA subdirectory
        $sraDir = $uploadDir . $uploadSRAAccession . "/";
        $sraCommand = "mkdir -m 777 $uploadDir/$uploadSRAAccession ; /home/inseqt/RNASEQ/sratoolkit.3.0.2-ubuntu64/bin/prefetch $uploadSRAAccession -T sra -O $uploadDir -q 2>/dev/null ; /home/inseqt/RNASEQ/sratoolkit.3.0.2-ubuntu64/bin/fasterq-dump $uploadDir/$uploadSRAAccession -O $uploadDir/$uploadSRAAccession -f --split-files -q 2>/dev/null ; gzip $uploadDir/$uploadSRAAccession/$uploadSRAAccession*.fastq ; rm -rf $uploadDir/$uploadSRAAccession/$uploadSRAAccession*.sra*";
        shell_exec($sraCommand);

        // Define file paths for paired files
        $file1 = $sraDir . $uploadSRAAccession . "_1.fastq.gz";
        $file2 = $sraDir . $uploadSRAAccession . "_2.fastq.gz";

        // Ensure up to 2 files exist and return their paths
        if (file_exists($file1) && file_exists($file2)) {
            echo "<p>Files $file1 and $file2 have been successfully processed and stored.</p>";
            $uploadedFilePaths[] = $file1 ;
            $uploadedFilePaths[] = $file2 ;
        } elseif (file_exists($file1)) {
            echo "<p>File $file1 has been successfully processed and stored.</p>";
            $uploadedFilePaths = [$file1] ;
        } else {
            echo "<p style='color: red;'>ERROR: No valid files were created for SRA accession $uploadSRAAccession.</p>";
        }

    }
    // Check for dropdown menu selection
    elseif (isset($_POST[$html_parameter . "_dropdown_menu_options"])) {
        $uploadDropdownMenu = $_POST[$html_parameter . "_dropdown_menu_options"];
        if ($uploadDropdownMenu == "silva_ref_file") {
            echo "<p>RiDB (SILVA SSU+LSU rRNA v138.1) selected, please wait...</p>";
            flush();

            $uploadFilePath = "/mnt/14C608D4C608B7CE/blast/ViRAE/DATA/HOST_GENOMES/SILVA_LSU+SSU_rRNA.prinseq-ns_max_p1.fasta.gz";
            $uploadedFilePaths = $uploadFilePath ; 
        } elseif ($uploadDropdownMenu == "homo_sapiens_ref_file") {
            echo "<p>Homo sapiens GRCh38 selected, please wait...</p>";
            flush();

            $uploadFilePath = "/mnt/14C608D4C608B7CE/blast/ViRAE/DATA/HOST_GENOMES/Homo_sapiens.GRCh38.cdna.all.fa.gz";
            $uploadedFilePaths = $uploadFilePath ;
        }
    }
    // Check for file link
    elseif (isset($_POST[$html_parameter . "_link"])) {
        $uploadLinks = $_POST[$html_parameter . "_link"];

        // Split the links by commas
        $linksArray = array_map('trim', explode(',', $uploadLinks));

        // Ensure no more than 2 links are provided
        if (count($linksArray) > 2) {
            $errorMessage = "ERROR: Please provide up to 2 Google Drive links only! Click OK to be redirected to the ViRAE file upload page.";
            
            echo "<script>alert('$errorMessage');</script>";
            echo "<meta http-equiv='refresh' content='1;url=https://srv-inseqt.med.duth.gr/ViRAE/HTML/ViRAE_FASTX_upload.html'>";
            die();
        }

        foreach ($linksArray as $uploadLink) {
        // Check if the link is a Google Drive link
            if (strpos($uploadLink, 'https://drive.google.com') === 0) {
                // Extract the file ID from the Google Drive link
                preg_match('/[-\w]{25,}/', $uploadLink, $idMatch);
                if (!isset($idMatch[0])) {
                    $errorMessage = "ERROR: Please provide a valid Google Drive link! Click OK to be redirected to the ViRAE file upload page.";

                    echo "<script>alert('$errorMessage');</script>";
                    echo "<meta http-equiv='refresh' content='1;url=https://srv-inseqt.med.duth.gr/ViRAE/HTML/ViRAE_FASTX_upload.html'>";
                    die();
                }
                $fileId = $idMatch[0];

                // Generate the direct download link
                $uploadLink = "https://drive.usercontent.google.com/download?id=" . $fileId . "&export=download&authuser=0";

                echo "<p>Processing Google Drive file with ID: $fileId</p>";
            
                // Fetch headers to check for filenames (for links like FileTransfer.io)
                $headers = get_headers($uploadLink, 1);

                // Ensure the response contains Content-Disposition or valid headers
                if (isset($headers['Content-Disposition'])) {
                    $linkType = $html_parameter . "_link";
                    $contentDisposition = $headers['Content-Disposition'];
                    preg_match('/filename="([^"]+)"/', $contentDisposition, $filenameMatch);
                    $uploadFilename = $filenameMatch[1];

                    $filesUploaded = [];
                    $uploadFilePath = $uploadDir . $uploadFilename;
                    echo "<p>File $uploadFilename is being uploaded, please wait...</p>";
                    shell_exec("aria2c -s 16 -x 16 -d $uploadDir $uploadLink");

                    if (file_exists($uploadFilePath)) {
                        $filesUploaded[] = $uploadFilename;
                        if ($linkType == "reads_file_link") {
                            $uploadedFilePaths[] = $uploadFilePath ;
                        } elseif ($linkType == "ref_file_link") {
                            $uploadedFilePaths = $uploadFilePath ;
                        }
                        // Final confirmation for successful uploads
                        echo "<p>File upload completed successfully for " . implode(", ", $filesUploaded) . ".</p>";
                    } else {
                        echo "<p style='color: red;'>ERROR saving $uploadFilename.</p>";
                    }  
                }
            } else {
                echo "<p style='color: red;'>Link is invalid OR has restricted access.</p>";
            }
        }
    }

    flush();

    return $uploadedFilePaths ;

}

// Define check_file_format function
function check_file_format($file_path, $format) {
    $fileName = pathinfo($file_path, PATHINFO_BASENAME);
    $fileExtension = pathinfo($file_path, PATHINFO_EXTENSION);
    $fastqSeqLines = 0;
    $fastqSeqidLines = 0;
    $fastqQualityLines = 0;
    $fastaSeqidLines = 0;
    $fastaSeqLines = 0;

    if ($format == "FASTQ") {
        if ($fileExtension == "gz") {
            $fastqSeqLines = intval(shell_exec("zcat < $file_path | awk 'NR % 4 == 2' | wc -l"));
            $fastqSeqidLines = intval(shell_exec("zcat < $file_path | awk 'NR % 4 == 1 && /^@/' | wc -l"));
            $fastqQualityLines = intval(shell_exec("zcat < $file_path | awk 'NR % 4 == 3 && /^+/' | wc -l"));
        } elseif ($fileExtension == "fastq" || $fileExtension == "fq") {
            $fastqSeqLines = intval(shell_exec("awk 'NR % 4 == 2' $file_path | wc -l"));
            $fastqSeqidLines = intval(shell_exec("awk 'NR % 4 == 1 && /^@/' $file_path | wc -l"));
            $fastqQualityLines = intval(shell_exec("awk 'NR % 4 == 3 && /^+/' $file_path | wc -l"));
        }

        if ($fastqSeqLines == $fastqSeqidLines && $fastqSeqidLines == $fastqQualityLines && $fastqSeqLines > 0 && $fastqSeqidLines > 0 && $fastqQualityLines > 0) {
            $fastqSeqstats = shell_exec("/home/inseqt/RNASEQ/seqstats/seqstats $file_path");
            echo "<p>Upload successful! FASTQ sequence statistics of $fileName</p>";
            echo "<pre>$fastqSeqstats</pre>";
        } else {
            echo "<p style='color: red;'>Invalid FASTQ formatted file</p>";

            if (file_exists($file_path)) {
                unlink($file_path);
            }
        }
    } elseif ($format == "FASTA") {
        if ($fileExtension == "fasta" || $fileExtension == "fa" || $fileExtension == "fna" || $fileExtension == "fsta" || $fileExtension == "gz") {
            $fastaSeqidLines = intval(shell_exec("seqtk seq -S $file_path | grep '^>' | wc -l"));
            $fastaSeqLines = intval(shell_exec("seqtk seq -S $file_path | grep -v '^>' | grep '^[[:alpha:]]' | wc -l"));
        }

        if ($fastaSeqLines == $fastaSeqidLines && $fastaSeqLines > 0 && $fastaSeqidLines > 0) {
            $fastaSeqstats = shell_exec("/home/inseqt/RNASEQ/seqstats/seqstats $file_path");
            echo "<p>Upload successful! FASTA sequence statistics of $fileName</p>";
            echo "<pre>$fastaSeqstats</pre>";
        } else {
            echo "<p style='color: red;'>Invalid FASTA formatted file</p>";

            if (file_exists($file_path)) {
                unlink($file_path);
            }
        }
    }

}

// Define run_virae function
function run_virae($reads_file_path, $ref_file_path, $output_dir) {
    echo "<h1>ViRAE execution result</h1>";
    echo "<p>Running ViRAE now, please wait...</p>";

    // Construct the command based on the number of reads files
    if (count($reads_file_path) == 1) {
        // SINGLE-END scenario
        $command = "/home/inseqt/COSTAS_CON/TOOLS/SCRIPTS/ViRAE.sh -1 {$reads_file_path[0]} -r $ref_file_path -o $output_dir";
    } elseif (count($reads_file_path) == 2) {
        // PAIRED-END scenario
        $command = "/home/inseqt/COSTAS_CON/TOOLS/SCRIPTS/ViRAE.sh -1 {$reads_file_path[0]} -2 {$reads_file_path[1]} -r $ref_file_path -o $output_dir";
    } 

    $output = shell_exec($command);
    echo "<pre>$output</pre>";
    
}

// Define download_virae_files function
function download_virae_files($reads_file_path, $ref_file_path) {
    global $downloadDir;

    // Extract common part of reads file names
    if (count($reads_file_path) == 2) {
        $file_name_1 = pathinfo($reads_file_path[0], PATHINFO_FILENAME);
        $file_name_2 = pathinfo($reads_file_path[1], PATHINFO_FILENAME);

        // Find the common prefix
        $commonPart = "";
        $minLength = min(strlen($file_name_1), strlen($file_name_2));

        // Compare characters in both strings up to the shortest length
        for ($i = 0; $i < $minLength; $i++) {
            if ($file_name_1[$i] === $file_name_2[$i]) {
                $commonPart .= $file_name_1[$i];
            } else {
                break; // Stop as soon as a mismatch is found
            }
        }

        $reads_file_name = $commonPart;

    } elseif (count($reads_file_path) == 1) {
        $reads_file_name = pathinfo($reads_file_path[0], PATHINFO_FILENAME);
    } else {
        $errorMessage = "ERROR: Invalid number of reads files provided for download! Click OK to be redirected to the ViRAE file upload page.";

        echo "<script>alert('$errorMessage');</script>";
        echo "<meta http-equiv='refresh' content='1;url=https://srv-inseqt.med.duth.gr/ViRAE/HTML/ViRAE_FASTX_upload.html'>";
    }

    $ref_file_name = pathinfo($ref_file_path, PATHINFO_FILENAME);
    #$downloadFileName = "ViRAE-${reads_file_name}_ON_${ref_file_name}.tar.gz";
    $downloadFileName = "ViRAE-${reads_file_name}_ON_${ref_file_name}.zip";

    #$command = "cd $downloadDir ; tar -czvf $downloadFileName ViRAE-${reads_file_name}_ON_${ref_file_name} ; rm -rf ViRAE-${reads_file_name}_ON_${ref_file_name} ";
    $command = "cd $downloadDir ; zip -r $downloadFileName ViRAE-${reads_file_name}_ON_${ref_file_name} ; rm -rf ViRAE-${reads_file_name}_ON_${ref_file_name} ";
    shell_exec($command);
    
    echo "<p><a href='https://srv-inseqt.med.duth.gr/ViRAE/FILE_STORAGE/ViRAE_downloads/$downloadFileName' download='$downloadFileName'>Download ViRAE files</a></p>";
}

// Main code
#echo "<html><head><title>Upload Status</title></head><body>";
echo "<h1>Upload Status</h1>";

echo "<h2>NGS reads file</h2>";
$uploadedReadsFilePaths = upload_method("reads_file", $uploadDir);

if (!empty($uploadedReadsFilePaths)) {
    foreach ($uploadedReadsFilePaths as $filePath) {
        check_file_format($filePath, "FASTQ");
    }

    echo "<h2>Reference file</h2>";
    $uploadRefFilePath = upload_method("ref_file", $uploadDir);

    check_file_format($uploadRefFilePath, "FASTA");

    if (file_exists($uploadRefFilePath)) {
        run_virae($uploadedReadsFilePaths, $uploadRefFilePath, $downloadDir);
        download_virae_files($uploadedReadsFilePaths, $uploadRefFilePath);

        $refFileUploadDropdownMenu = isset($_POST["ref_file_dropdown_menu_options"]) ? $_POST["ref_file_dropdown_menu_options"] : "";

        if (!$refFileUploadDropdownMenu) {
            shell_exec("rm -rf $uploadRefFilePath.amb $uploadRefFilePath.ann $uploadRefFilePath.bwt $uploadRefFilePath.pac $uploadRefFilePath.sa");
        }
    } else {
        $errorMessage = "Invalid input FASTA file! Click OK to be redirected to the ViRAE file upload page.";

        $readsFileSRAAccession = isset($_POST["reads_file_sra_accession"]) ? $_POST["reads_file_sra_accession"] : "";

        if ($readsFileSRAAccession) {
            shell_exec("rm -rf $uploadDir/$readsFileSRAAccession");
        }

        echo "<script>alert('$errorMessage');</script>";
        echo "<meta http-equiv='refresh' content='1;url=https://srv-inseqt.med.duth.gr/ViRAE/HTML/ViRAE_FASTX_upload.html'>";
    }
} else {
    $errorMessage = "Invalid input FASTQ file! Click OK to be redirected to the ViRAE file upload page.";

    $readsFileSRAAccession = isset($_POST["reads_file_sra_accession"]) ? $_POST["reads_file_sra_accession"] : "";
    $refFileUploadDropdownMenu = isset($_POST["ref_file_dropdown_menu_options"]) ? $_POST["ref_file_dropdown_menu_options"] : "";

    if ($readsFileSRAAccession) {
        shell_exec("rm -rf $uploadDir/$readsFileSRAAccession");
    }

    echo "<script>alert('$errorMessage');</script>";
    echo "<meta http-equiv='refresh' content='1;url=https://srv-inseqt.med.duth.gr/ViRAE/HTML/ViRAE_FASTX_upload.html'>";
}