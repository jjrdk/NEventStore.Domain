properties {
    $base_directory = Resolve-Path ..
    $publish_directory = "$base_directory\publish-net40"
    $build_directory = "$base_directory\build"
    $src_directory = "$base_directory\src"
    $output_directory = "$base_directory\output"
    $packages_directory = "$src_directory\packages"
    $sln_file = "$src_directory\NEventStore.Domain.sln"
    $target_config = "Release"
    $framework_version = "v4.0"
    $assemblyInfoFilePath = "$src_directory\VersionAssemblyInfo.cs"

    $xunit_path = "$base_directory\bin\xunit.runners.1.9.1\tools\xunit.console.clr4.exe"
    $ilMergeModule.ilMergePath = "$base_directory\bin\ilmerge-bin\ILMerge.exe"
    $nuget_dir = "$src_directory\.nuget"

	if($build_number -eq $null) {
		$build_number = 0
	}
	
}

task default -depends Build

task Build -depends Clean, UpdateVersion, Compile, Test

task UpdateVersion {
    $version = Get-Version $assemblyInfoFilePath
    "Version: $version"
	$oldVersion = New-Object Version $version
	$newVersion = New-Object Version ($oldVersion.Major, $oldVersion.Minor, $oldVersion.Build, $build_number)
	Update-Version $newVersion $assemblyInfoFilePath
}

task Compile {
	exec { msbuild /nologo /verbosity:quiet $sln_file /p:Configuration=$target_config /t:Clean }
	exec { msbuild /nologo /verbosity:quiet $sln_file /p:Configuration=$target_config /p:TargetFrameworkVersion=v4.0 }
}

task Test -depends RunUnitTests

task RunUnitTests {
	"Unit Tests"
	EnsureDirectory $output_directory
	Invoke-XUnit -Path $src_directory -TestSpec '*NEventStore.Domain.Tests.dll' `
    -SummaryPath $output_directory\unit_tests.xml `
    -XUnitPath $xunit_path
}

task Package -depends Build {
	mkdir $publish_directory\bin | out-null
    copy "$src_directory\NEventStore.Domain\bin\$target_config\NEventStore.Domain.???" "$publish_directory\bin"
}

task Clean {
	Clean-Item $publish_directory -ea SilentlyContinue
    Clean-Item $output_directory -ea SilentlyContinue
}

task NuGetPack -depends Package {
    $versionString = Get-Version $assemblyInfoFilePath
	$version = New-Object Version $versionString
	$packageVersion = $version.Major.ToString() + "." + $version.Minor.ToString() + "." + $version.Build.ToString() + "." + $build_number.ToString()
	"Package Version: $packageVersion"
	gci -r -i *.nuspec "$nuget_dir" |% { .$nuget_dir\nuget.exe pack $_ -basepath $base_directory -o $publish_directory -version $packageVersion }
}

function EnsureDirectory {
	param($directory)

	if(!(test-path $directory))
	{
		mkdir $directory
	}
}
