//
//  BackupViewController.swift
//  altering
//
//  Backup and Restore functionality
//

import UIKit
import CoreData

class BackupViewController: UITableViewController, UIDocumentPickerDelegate {
    
    // MARK: - Properties
    
    private var context: NSManagedObjectContext!
    private var exportedFileURL: URL?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Backup & Restore"
        navigationItem.largeTitleDisplayMode = .never
        
        // Get context from AppDelegate
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            context = appDelegate.persistentContainer.viewContext
        }
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Export
        case 1: return 2 // Import options
        case 2: return 1 // Info
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Export Data"
        case 1: return "Import Data"
        case 2: return "Information"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return "Export all your workout data to a JSON file. You can save it to Files, email it, or store it in cloud storage."
        case 1: return "Import data from a backup file. Choose whether to merge with existing data or replace it completely."
        case 2: return nil
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        
        switch indexPath.section {
        case 0: // Export
            cell.textLabel?.text = "Export All Data"
            cell.textLabel?.textColor = .systemBlue
            
        case 1: // Import
            if indexPath.row == 0 {
                cell.textLabel?.text = "Import & Merge with Existing Data"
                cell.textLabel?.textColor = .systemGreen
            } else {
                cell.textLabel?.text = "Import & Replace All Data"
                cell.textLabel?.textColor = .systemOrange
            }
            
        case 2: // Info
            cell.textLabel?.text = "About Backup & Restore"
            cell.textLabel?.textColor = .label
            cell.accessoryType = .none
            
        default:
            break
        }
        
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0: // Export
            exportData()
            
        case 1: // Import
            let clearExisting = (indexPath.row == 1)
            if clearExisting {
                showReplaceWarning()
            } else {
                importData(clearExisting: false)
            }
            
        case 2: // Info
            showInfoAlert()
            
        default:
            break
        }
    }
    
    // MARK: - Export Functions
    
    private func exportData() {
        guard let context = context else {
            showAlert(title: "Error", message: "Unable to access data")
            return
        }
        
        // Show loading
        let loadingAlert = UIAlertController(title: "Exporting...", message: "Please wait", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        // Export on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = DataExporter.exportAllData(context: context)
            
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    self?.handleExportResult(result)
                }
            }
        }
    }
    
    private func handleExportResult(_ result: DataExporter.ExportResult) {
        if result.success, let fileURL = result.fileURL {
            exportedFileURL = fileURL
            
            let alert = UIAlertController(
                title: "Export Successful",
                message: "Exported \(result.recordCount) records. What would you like to do with the backup file?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] _ in
                self?.shareFile(fileURL)
            })
            
            alert.addAction(UIAlertAction(title: "Save to Files", style: .default) { [weak self] _ in
                self?.saveToFiles(fileURL)
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            present(alert, animated: true)
            
        } else {
            let errorMessage = result.error?.localizedDescription ?? "Unknown error"
            showAlert(title: "Export Failed", message: errorMessage)
        }
    }
    
    private func shareFile(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = view
        present(activityVC, animated: true)
    }
    
    private func saveToFiles(_ url: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [url])
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }
    
    // MARK: - Import Functions
    
    private func importData(clearExisting: Bool) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.shouldShowFileExtensions = true
        
        // Store clearExisting flag
        documentPicker.view.tag = clearExisting ? 1 : 0
        
        present(documentPicker, animated: true)
    }
    
    private func showReplaceWarning() {
        let alert = UIAlertController(
            title: "⚠️ Warning",
            message: "This will DELETE ALL your current data and replace it with the backup file. This cannot be undone. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Replace All Data", style: .destructive) { [weak self] _ in
            self?.importData(clearExisting: true)
        })
        
        present(alert, animated: true)
    }
    
    private func performImport(from url: URL, clearExisting: Bool) {
        guard let context = context else {
            showAlert(title: "Error", message: "Unable to access data")
            return
        }
        
        // Show loading
        let loadingAlert = UIAlertController(title: "Importing...", message: "Please wait", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        // Import on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = DataImporter.importData(from: url, context: context, clearExisting: clearExisting)
            
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    self?.handleImportResult(result)
                }
            }
        }
    }
    
    private func handleImportResult(_ result: DataImporter.ImportResult) {
        if result.success {
            let alert = UIAlertController(
                title: "Import Successful",
                message: result.message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                // Pop back to previous screen
                self?.navigationController?.popViewController(animated: true)
            })
            
            present(alert, animated: true)
            
        } else {
            showAlert(title: "Import Failed", message: result.message)
        }
    }
    
    // MARK: - Document Picker Delegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // Check if this is import (tag 0 or 1) or export (no tag handling needed)
        let clearExisting = (controller.view.tag == 1)
        
        // Check if file is accessible
        guard url.startAccessingSecurityScopedResource() else {
            showAlert(title: "Error", message: "Unable to access file")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Perform import
        performImport(from: url, clearExisting: clearExisting)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // User cancelled
    }
    
    // MARK: - Info Alert
    
    private func showInfoAlert() {
        let message = """
        Backup & Restore allows you to:
        
        • Export all your workout data to a JSON file
        • Save backups to Files, iCloud Drive, or share via email
        • Transfer data between devices
        • Keep multiple backup versions
        
        Export Format:
        All exercises, workouts, programs, and settings are saved in a human-readable JSON format.
        
        Import Options:
        • Merge: Adds backup data to existing data
        • Replace: Deletes all current data first
        
        Tips:
        • Create regular backups before major changes
        • Store backups in multiple locations
        • Test restore on a second device first
        """
        
        let alert = UIAlertController(title: "About Backup & Restore", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Helper Functions
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

