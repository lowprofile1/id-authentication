# MOSIP ID Authentication Workflow Validation Script
# This script validates the GitHub Actions workflow files

param(
    [Parameter(Mandatory=$false)]
    [string]$WorkflowDir = ".github\workflows"
)

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-YamlSyntax {
    param([string]$FilePath)
    
    Write-Info "Validating $FilePath..."
    
    try {
        # Basic YAML syntax check - look for common issues
        $content = Get-Content $FilePath -Raw
        
        # Check for basic YAML structure
        if ($content -notmatch 'name:') {
            Write-Error "${FilePath}: Missing 'name' field"
            return $false
        }
        
        if ($content -notmatch 'on:') {
            Write-Error "${FilePath}: Missing 'on' field"
            return $false
        }
        
        if ($content -notmatch 'jobs:') {
            Write-Error "${FilePath}: Missing 'jobs' field"
            return $false
        }
        
        # Check for balanced quotes
        $singleQuotes = ($content.ToCharArray() | Where-Object { $_ -eq "'" }).Count
        $doubleQuotes = ($content.ToCharArray() | Where-Object { $_ -eq '"' }).Count
        
        if ($singleQuotes % 2 -ne 0) {
            Write-Error "${FilePath}: Unbalanced single quotes"
            return $false
        }
        
        if ($doubleQuotes % 2 -ne 0) {
            Write-Error "${FilePath}: Unbalanced double quotes"
            return $false
        }
        
        Write-Success "${FilePath}: Basic syntax validation passed"
        return $true
    }
    catch {
        Write-Error "${FilePath}: Error reading file - $_"
        return $false
    }
}

function Test-WorkflowStructure {
    param([string]$FilePath)
    
    Write-Info "Checking workflow structure for $FilePath..."
    
    try {
        $content = Get-Content $FilePath -Raw
        
        # Check for required workflow elements
        $requiredElements = @('name:', 'on:', 'jobs:')
        $missingElements = @()
        
        foreach ($element in $requiredElements) {
            if ($content -notmatch $element) {
                $missingElements += $element
            }
        }
        
        if ($missingElements.Count -gt 0) {
            Write-Error "${FilePath}: Missing required elements: $($missingElements -join ', ')"
            return $false
        }
        
        # Check for common workflow patterns
        if ($content -match 'uses:\s*actions/checkout') {
            Write-Success "${FilePath}: Contains checkout action"
        }
        
        if ($content -match 'runs-on:') {
            Write-Success "${FilePath}: Contains runs-on specification"
        }
        
        Write-Success "${FilePath}: Structure validation passed"
        return $true
    }
    catch {
        Write-Error "${FilePath}: Error checking structure - $_"
        return $false
    }
}

# Main execution
Write-Info "Starting workflow validation..."

$workflowFiles = Get-ChildItem -Path $WorkflowDir -Filter "*.yml" -File | Where-Object { $_.Name -ne "config.yml" }
$allValid = $true

foreach ($file in $workflowFiles) {
    Write-Info "Validating $($file.Name)..."
    
    $syntaxValid = Test-YamlSyntax $file.FullName
    $structureValid = Test-WorkflowStructure $file.FullName
    
    if (-not $syntaxValid -or -not $structureValid) {
        $allValid = $false
    }
    
    Write-Host ""
}

if ($allValid) {
    Write-Success "All workflow files passed validation!"
    Write-Info "Workflow files validated:"
    foreach ($file in $workflowFiles) {
        Write-Host "  - $($file.Name)" -ForegroundColor Green
    }
} else {
    Write-Error "Some workflow files failed validation. Please check the errors above."
    exit 1
}

Write-Info "Validation complete!"
