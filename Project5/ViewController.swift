//
//  ViewController.swift
//  Project5
//
//  Created by Grant Watson on 9/8/22.
//

import UIKit

class ViewController: UITableViewController {
    var allWords = [String]()
    var usedWords = [String]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(startGame))
        
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                allWords = startWords.components(separatedBy: "\n")
            }
        }
        
        if allWords.isEmpty {
            allWords = ["silkworm"]
        }
        
        let defaults = UserDefaults.standard
        if let gameProgress = defaults.object(forKey: "usedWords") as? Data {
            if let startWord = defaults.object(forKey: "startingWord") as? Data {
                let decoder = JSONDecoder()
                do {
                    usedWords = try decoder.decode([String].self, from: gameProgress)
                    title = try decoder.decode(String.self, from: startWord)
                } catch {
                    print("Failed to load starting words.")
                }
            }
        } else {
            startGame()
        }
        
        if let startWord = defaults.object(forKey: "startingWord") as? Data {
            let decoder = JSONDecoder()
            do {
                title = try decoder.decode(String.self, from: startWord)
            } catch {
                print("Failed to load starting words.")
            }
        } else {
            startGame()
        }
    }
    
    @objc func startGame() {
        title = allWords.randomElement()
        usedWords.removeAll()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row].lowercased()
        return cell
    }
    
    @objc func promptForAnswer() {
        let ac = UIAlertController(title: "Enter answer", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] _ in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    func submit(_ answer: String) {
        let lowerAnswer = answer.lowercased()
        
        if isReal(word: lowerAnswer) {
            if isPossible(word: lowerAnswer) {
                if isOriginal(word: lowerAnswer) {
                    if lowerAnswer == title {
                        showErrorMessage(title: "Answer is same as starting word", message: "Please try a different word that isn't the same as the starting word.")
                    } else {
                        usedWords.insert(lowerAnswer, at: 0)
                        
                        let indexPath = IndexPath(row: 0, section: 0)
                        tableView.insertRows(at: [indexPath], with: .automatic)
                        saveProgress()
                        
                        return
                    }
                } else {
                    showErrorMessage(title: "Word already used", message: "Try to create a new word not already used.")
                }
            } else {
                guard let title = title else { return }
                showErrorMessage(title: "Word not possible", message: "That word cannot be formed from \(title.lowercased()).")
            }
        } else {
            showErrorMessage(title: "Word not recognized", message: "Please check your spelling and try again.")
        }
    }
    
    func isPossible(word: String) -> Bool {
        guard var tempWord = title?.lowercased() else { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }

        return true
    }
    
    func isOriginal(word: String) -> Bool {
        return !usedWords.contains(word)
    }
    
    func isReal(word: String) -> Bool {
        if word.count > 3 {
            let checker = UITextChecker()
            let range = NSRange(location: 0, length: word.utf16.count)
            let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
            return misspelledRange.location == NSNotFound
        } else {
            showErrorMessage(title: "Word is too short", message: "Please choose a word longer than three letters.")
            return false
        }
    }
    
    func showErrorMessage(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func saveProgress() {
        let encoder = JSONEncoder()
        if let saveData = try? encoder.encode(usedWords) {
            if let word = try? encoder.encode(title) {
                let defaults = UserDefaults.standard
                defaults.set(word, forKey: "startingWord")
                defaults.set(saveData, forKey: "usedWords")
            }
        } else {
            print("Unable to save used words.")
        }
    }
}

