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

// Define upload method function
function upload_method($html_parameter, $uploadDir) {
    global $uploadDir;

    // Check for file upload
    if (isset($_FILES[$html_parameter . "_dialog"])) {
        $uploadFile = $_FILES[$html_parameter . "_dialog"];
        $uploadFileName = $uploadFile["name"];
        $uploadFilePath = $uploadDir . $uploadFileName;

        echo "<p>File $uploadFileName is being uploaded, please wait...</p>";
        flush();
        
        if (move_uploaded_file($uploadFile["tmp_name"], $uploadFilePath)) {
            return $uploadFilePath;
        } else {
            die("Cannot open $uploadFilePath");
        }
    }
    // Check for SRA accession
    elseif (isset($_POST[$html_parameter . "_sra_accession"])) {
        $uploadSRAAccession = $_POST[$html_parameter . "_sra_accession"];

        echo "<p>File $uploadSRAAccession is being uploaded, please wait...</p>";
        flush();

        $sraCommand = "mkdir -m 777 $uploadDir/$uploadSRAAccession ; /home/inseqt/RNASEQ/sratoolkit.3.0.2-ubuntu64/bin/prefetch $uploadSRAAccession -T sra -O $uploadDir -q 2>/dev/null ; /home/inseqt/RNASEQ/sratoolkit.3.0.2-ubuntu64/bin/fasterq-dump $uploadDir/$uploadSRAAccession -O $uploadDir/$uploadSRAAccession -f --split-spot -q 2>/dev/null ; gzip $uploadDir/$uploadSRAAccession/$uploadSRAAccession.fastq ; rm -rf $uploadDir/$uploadSRAAccession/$uploadSRAAccession.sra";
        shell_exec($sraCommand);

        $uploadFilePath = $uploadDir . $uploadSRAAccession . "/" . $uploadSRAAccession . ".fastq.gz";

        return $uploadFilePath;
    }
    // Check for dropdown menu selection
    elseif (isset($_POST[$html_parameter . "_dropdown_menu_options"])) {
        $uploadDropdownMenu = $_POST[$html_parameter . "_dropdown_menu_options"];
        if ($uploadDropdownMenu == "silva_ref_file") {
            echo "<p>RiDB (SILVA SSU+LSU rRNA v138.1) selected, please wait...</p>";
            flush();

            $uploadFilePath = "/mnt/14C608D4C608B7CE/blast/ViRAE/DATA/HOST_GENOMES/SILVA_LSU+SSU_rRNA.prinseq-ns_max_p1.fasta.gz";
            return $uploadFilePath;
        } elseif ($uploadDropdownMenu == "homo_sapiens_ref_file") {
            echo "<p>Homo sapiens GRCh38 selected, please wait...</p>";
            flush();

            $uploadFilePath = "/mnt/14C608D4C608B7CE/blast/ViRAE/DATA/HOST_GENOMES/Homo_sapiens.GRCh38.cdna.all.fa.gz";
            return $uploadFilePath;
        }
    }
    // Check for file link
    elseif (isset($_POST[$html_parameter . "_link"])) {
        $uploadLink = $_POST[$html_parameter . "_link"];

        // Check and modify the FileTransfer URL if needed
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

                // Save the downloaded content to a local file using aria2c
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

// Define check_file_format function
function check_file_format($file_path, $format) {
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
            echo "<p>Upload successful! FASTQ sequence statistics</p>";
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
            echo "<p>Upload successful! FASTA sequence statistics</p>";
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

    $command = "/home/inseqt/COSTAS_CON/TOOLS/SCRIPTS/ViRAE.sh -i $reads_file_path -r $ref_file_path -o $output_dir";
    $output = shell_exec($command);
    echo "<pre>$output</pre>";
    
}

// Define download_virae_files function
function download_virae_files($reads_file_path, $ref_file_path) {
    global $downloadDir;

    $reads_file_name = pathinfo($reads_file_path, PATHINFO_FILENAME);
    $ref_file_name = pathinfo($ref_file_path, PATHINFO_FILENAME);
    #$downloadFileName = "ViRAE-${reads_file_name}_ON_${ref_file_name}.tar.gz";
    $downloadFileName = "ViRAE-${reads_file_name}_ON_${ref_file_name}.zip";

    #$command = "cd $downloadDir ; tar -czvf $downloadFileName ViRAE-${reads_file_name}_ON_${ref_file_name} ; rm -rf ViRAE-${reads_file_name}_ON_${ref_file_name} ";
    $command = "cd $downloadDir ; zip -r $downloadFileName ViRAE-${reads_file_name}_ON_${ref_file_name} ; rm -rf ViRAE-${reads_file_name}_ON_${ref_file_name} ";
    shell_exec($command);
    
    echo "<p><a href='https://srv-inseqt.med.duth.gr/ViRAE/FILE_STORAGE/ViRAE_downloads/$downloadFileName' download='$downloadFileName'>Download ViRAE files</a></p>";
}

// Main code
echo "<html><head><title>Upload Status</title></head><body>";
echo "<h1>Upload Status</h1>";

echo "<h2>NGS reads file</h2>";
$uploadReadsFilePath = upload_method("reads_file", $uploadDir);
check_file_format($uploadReadsFilePath, "FASTQ");

if (file_exists($uploadReadsFilePath)) {
    echo "<h2>Reference file</h2>";
    $uploadRefFilePath = upload_method("ref_file", $uploadDir);
    check_file_format($uploadRefFilePath, "FASTA");

    if (file_exists($uploadRefFilePath) && $uploadReadsFilePath !== $uploadRefFilePath) {
        run_virae($uploadReadsFilePath, $uploadRefFilePath, $downloadDir);
        download_virae_files($uploadReadsFilePath, $uploadRefFilePath);

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
} elseif (!file_exists($uploadReadsFilePath)) {
    $errorMessage = "Invalid input FASTQ file! Click OK to be redirected to the ViRAE file upload page.";

    $readsFileSRAAccession = isset($_POST["reads_file_sra_accession"]) ? $_POST["reads_file_sra_accession"] : "";
    $refFileUploadDropdownMenu = isset($_POST["ref_file_dropdown_menu_options"]) ? $_POST["ref_file_dropdown_menu_options"] : "";

    if ($readsFileSRAAccession) {
        shell_exec("rm -rf $uploadDir/$readsFileSRAAccession");
    }

    echo "<script>alert('$errorMessage');</script>";
    echo "<meta http-equiv='refresh' content='1;url=https://srv-inseqt.med.duth.gr/ViRAE/HTML/ViRAE_FASTX_upload.html'>";
}
