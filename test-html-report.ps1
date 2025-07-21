# Test HTML Report Generation
Import-Module ".\modules\ReportGenerator.psm1" -Force

# Create test data
$testResults = @{
    DumpPath = 'C:\Test\RocketChat\Support\Dump'
    Summary = @{
        TotalIssues = 8
    }
    SettingsAnalysis = @{
        SecuritySettings = @{
            'TwoFactorAuth' = $true
            'LDAP_Enable' = $false
            'SAML_Custom_Default' = $true
            'LDAP_Encryption' = 'ssl'
        }
        PerformanceSettings = @{
            'Message_MaxAllowedSize' = 25000
            'FileUpload_MaxFileSize' = 104857600
            'Threads_Pool_Size' = 10
            'Rate_Limiter_Limit_RegisterUser' = 1
        }
        Settings = @{
            'Accounts_TwoFactorAuthentication_Enabled' = $true
            'LDAP_Enable' = $false
            'Email_Protocol' = 'SMTP'
            'API_Enable_CORS' = $true
            'FileUpload_Storage_Type' = 'GridFS'
            'Omnichannel_enabled' = $true
            'Message_AllowEditing' = $true
            'Layout_Sidenav_Footer' = 'Custom Footer Text'
            'Push_enable' = $false
        }
        Issues = @(
            @{
                Severity = 'Warning'
                Message = 'LDAP authentication is disabled but configured'
                Setting = 'LDAP_Enable'
            },
            @{
                Severity = 'Error'
                Message = 'File upload size exceeds recommended limit'
                Setting = 'FileUpload_MaxFileSize'
            }
        )
    }
}

# Generate HTML report
Write-Host "Generating HTML report..." -ForegroundColor Green
$html = New-HTMLReport -Results $testResults

# Save to file
$reportPath = "test-report.html"
$html | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "HTML report generated successfully at: $reportPath" -ForegroundColor Green

# Open in default browser
Write-Host "Opening report in default browser..." -ForegroundColor Yellow
Start-Process $reportPath
