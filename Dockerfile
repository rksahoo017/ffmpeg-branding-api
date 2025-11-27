<?php

// Render FFmpeg API URL
$API_URL = "https://ffmpeg-branding-api.onrender.com/brand";

// Validate input
if (!isset($_FILES['video']) || !isset($_FILES['logo']) || !isset($_POST['brandtext'])) {
    die("Missing input.");
}

$brandtext = $_POST['brandtext'];

// Prepare uploads
$videoFile = curl_file_create(
    $_FILES['video']['tmp_name'],
    $_FILES['video']['type'],
    $_FILES['video']['name']
);

$logoFile = curl_file_create(
    $_FILES['logo']['tmp_name'],
    $_FILES['logo']['type'],
    $_FILES['logo']['name']
);

$postFields = [
    'video'     => $videoFile,
    'logo'      => $logoFile,
    'brandtext' => $brandtext
];

// cURL request to the FFmpeg API
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $API_URL);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $postFields);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 600);

$response = curl_exec($ch);

if ($response === false) {
    die("Error contacting FFmpeg API: " . curl_error($ch));
}

$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

// If API did not return 200, show RAW response for debugging
if ($http_code !== 200) {
    header("Content-Type: text/plain; charset=utf-8");
    echo "HTTP code from API: {$http_code}\n\n";
    echo "Raw response from API:\n";
    echo $response;
    exit;
}

// Save the output video
$outputName = "branded_" . time() . ".mp4";
file_put_contents($outputName, $response);

// Show download link
echo "<h2>Branded Video Ready</h2>";
echo "<p><a href='$outputName' download>⬇ Download Branded Reel</a></p>";

?>
