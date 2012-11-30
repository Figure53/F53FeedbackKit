<?php
/*
 * Copyright 2008, Torsten Curdt
 * Copyright 2012, Figure 53, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

include 'config.php';
include 'errorlog.php';

function dirs($dir)
{
    $fh = opendir($dir);

    while($entryName = readdir($fh)) {
        if ($entryName{0} != '.') {
	        $dirArray[$entryName] = $entryName;            
        }
    }

    closedir($fh);
    
    return $dirArray;
}

function uniq()
{
    return date('Y-m-d\\TH:i:s-') . md5(getmypid().uniqid(rand()).$_SERVER[‘SERVER_NAME’]);
}

function write_to_file($data,$filename)
{
   $fh = fopen($filename, "w");
   if (!$fh) {
      // failed to create file
      echo "ERR 004\n";
      echo "failed to create file" . $filename;
   }
   fwrite($fh, $data);
   fclose($fh);
}

$project_raw = $_GET['project'];
$project = preg_replace('/[^(0-9A-Za-z)]*/', '', $project_raw);

if ($project != $project_raw) {
    echo "ERR 007\n";
    echo "project name mismatch";
    exit;    
}

$project_dir = $feedback_dir . $project . '/';

if(!is_dir($project_dir)) {
    // no project directory
    
    if (!$create_project_dirs) {
        // no project directory (and not configured to create one)
        echo "ERR 002\n";
        echo "no such project";
        exit;        
    }
    
    if (count(dirs($feedback_dir)) > $feedback_max_project) {
        // too many projects
        echo "ERR 009\n";
        echo "too many projects";
        exit;                
    }
    
    // create project dir
    if (!mkdir($project_dir)) {
        // failed to create project directory
        echo "ERR 008\n";
        echo "could not create project dir";
        exit;
    }
}

$submission_dir = $project_dir . uniq() . '/';

if (!mkdir($submission_dir)) {
    // failed to create submission directory
    echo "ERR 003\n";
    echo "failed to create submission directory";
    exit;
}

$postdata = file_get_contents("php://input");
$dest = $submission_dir . '/raw_json';
write_to_file($postdata,$dest);

$json_data = json_decode($postdata);
foreach ($json_data as $key => $value) {
   $dest = $submission_dir . $key;
   if ($key == 'documents') {
      if (mkdir($dest)) {
         foreach ($value as $docname => $docdata) {
            $doc_dest = $dest . '/' . $docname;
            $decoded_data = base64_decode($docdata);
            write_to_file($decoded_data,$doc_dest);
         }
      }
      else {
         echo "failed to create direcory for documents";
      }
   }
   else {
      write_to_file($value,$dest);
   }
}

?>
