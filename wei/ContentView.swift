//
//  ContentView.swift
//  wei
//
//  Created by Kevin Yien on 2/5/20.
//  Copyright © 2020 Kevin Yien. All rights reserved.
//

import SwiftUI
import CoreData
import UserNotifications


struct PersonRow: View {
    var person: Person
    
    var body: some View {
        Text(person.name ?? "Dr. Strange?!")
    }
}


struct ContentView: View {
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
        entity: Person.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Person.sortOrder, ascending: true)]
    ) var activePeople: FetchedResults<Person>
    
    @State private var personName: String = ""
    @State private var showAdd: Bool = false
    @State private var showHelp: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(activePeople) { person in
                        Button(action: {
                            self.updatePerson(person)
                        }) {
                            PersonRow(person: person)
                        }
                    }.onDelete {indexSet in
                        let deletePerson = self.activePeople[indexSet.first!]
                        self.context.delete(deletePerson)
                        
                        do {
                            try self.context.save()
                        } catch {
                            print(error)
                        }
                        
                    }
                }
                .navigationBarTitle(Text("People"))
                .navigationBarItems(trailing:
                    Button(action: {
                        self.showHelp = true
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                    .accentColor(.white)
                    .imageScale(.large)
                    .padding(12.0)
                    .frame(width: 50, height: 50, alignment: .center)
                    .sheet(isPresented: $showHelp) {
                        VStack(alignment: .leading) {
                            Text("This is wei — a simple app for spontaneous connection.")
                                .lineSpacing(4.0)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                                .frame(height:18.0)
                            Text("It doesn't do much.")
                                .lineSpacing(4.0)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                                .frame(height:18.0)
                            Text("Add people and it will remind you to reach out at a random time every week. After you contact someone (outside the app), tap their name to send them to the bottom of the list. That's it.")
                                .lineSpacing(4.0)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                                .frame(height:18.0)
                            Text("The name `wei` is an homage to the way people answer the phone in Chinese culture. I hope these simple reminders help you stay connected with the people you care about.")
                                .lineSpacing(4.0)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 64.0)
                    
                    }
                )
                
                // FAB for adding people
                //requests notification permission first time
                Button(action: {
                    self.showAdd = true
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                        if success {
                            print("All set!")
                        } else if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                }) {
                    Image(systemName: "plus")
                }
                .accentColor(.white)
                .padding(24.0)
                .frame(width: 50, height: 50, alignment: .center)
                .contentShape(Rectangle())
                .background(Color("SlateBlue"))
                .mask(Circle())
                .imageScale(.large)
                .sheet(isPresented: $showAdd) {
                    VStack {
                        TextField("Name", text: self.$personName)
                            .padding(.vertical, 4.0)
                            .multilineTextAlignment(.center)
                        Spacer()
                            .frame(height: 24.0)
                        // This is the button to save the person entry
                        Button(action: {
                            self.addPerson() // call up ADD sheet
                            self.personName = "" // reset input field
                            self.showAdd = false // dismiss ADD sheet
                            
                            // Configure copy for notification
                            let content = UNMutableNotificationContent()
                            content.title = "wei?"
                            content.subtitle = "Surprise someone by sending a quick message!"
                            content.sound = UNNotificationSound.default
                            
                            // Configure the randomly recurring date.
                            let randomDay = Int.random(in: 1..<7)
                            let randomTime = Int.random(in: 8..<18)
                            var dateComponents = DateComponents()
                            dateComponents.calendar = Calendar.current
                            dateComponents.weekday = randomDay
                            dateComponents.hour = randomTime
                            
                            // manual notification for testing
                            
                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
                            
                            // Create the trigger as a repeating event.
                            //                    let trigger = UNCalendarNotificationTrigger(
                            //                             dateMatching: dateComponents, repeats: true)
                            
                            // choose a random identifier
                            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                            
                            // add our notification request
                            UNUserNotificationCenter.current().add(request)
                            
                            
                            
                            
                        }) {
                            Text("Remember")
                        }
                        .font(.headline)
                        .padding(12.0)
                        .accentColor(.white)
                        .background(Color("SlateBlue"))
                        .cornerRadius(/*@START_MENU_TOKEN@*/8.0/*@END_MENU_TOKEN@*/)
                        
                        
                        
                    }
                }
                
                
            }
        }
        
        
    }
    
    
    func addPerson() {
        let newPerson = Person(context: context)
        newPerson.id = UUID()
        newPerson.name = personName
        newPerson.sortOrder = Date()
        
        do {
            try context.save()
        } catch {
            print(error)
        }
    }
    
    func updatePerson(_ person: Person) {
        let personID = person.id! as NSUUID
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "id == %@", personID as CVarArg)
        fetchRequest.fetchLimit = 1
        do {
            let test = try context.fetch(fetchRequest)
            let personUpdate = test[0] as! NSManagedObject
            personUpdate.setValue(Date(), forKey: "sortOrder")
        } catch {
            print(error)
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
