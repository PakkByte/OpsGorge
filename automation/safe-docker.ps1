param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$CMD = $Args -join " "
$VOLUME_NAME = "automation_postgres_data"

if ($CMD -match "down -v|volume rm|system prune|compose down --volumes") {
    Write-Host "WARNING: This will permanently delete Docker volumes, including possible data loss in: $VOLUME_NAME"
    $CONFIRM = Read-Host "Type YES to continue or anything else to abort"
    if ($CONFIRM -ne "YES") {
        Write-Host "Operation cancelled. Volume $VOLUME_NAME is safe."
        exit 1
    }
}

docker $CMD
