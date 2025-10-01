<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "uplaod max size: ".ini_get('upload_max_filesize');
echo "<br>";
echo "post max size: ".ini_get('post_max_size');
echo "<br>";
echo "max execution time : ".ini_get('max_execution_time');
echo "<br>";
echo "memory limit: ".ini_get('memory_limit');
echo "<br>";
echo "upload tmp dir: ".ini_get('upload_tmp_dir');
echo "<br>";
echo "path:".php_ini_loaded_file();
echo "<br>";
echo "<br>";

   if(isset($_FILES['test'])){
      $errors= array();
      $file_name = $_FILES['test']['name'];
      $file_size =$_FILES['test']['size'];
      $file_tmp =$_FILES['test']['tmp_name'];
      $file_type=$_FILES['test']['type'];
      if (!file_exists('upload_test')) {
        mkdir('upload_test', 0777, true);
        }
      if(empty($errors)==true){
         move_uploaded_file($file_tmp,"upload_test/".$file_name);
         echo "Success";
      }else{
         print_r($errors);
      }
   }
?>
<html>
   <body>
      <form action="" method="POST" enctype="multipart/form-data">
         <input type="file" name="test" />
         <input type="submit"/>
      </form>
   </body>
</html>
