//
//  ThreadManager.swift
//  ChatGPT
//
//  Created by Jose Miguel Torres Chavez Nava on 17/04/24.
//

import Foundation

struct Message: Codable {
    let role: String
    let content: String
}

struct Thread: Codable {
    var id: String?
    var object: String?
    var assistant_id: String?
    var created_at: Int? // Unix timestamp del momento de creación
    var metadata: [String: String]?
}

/// Función para crear un thread en la API de OpenAI. Puede ser vacío o contener mensajes iniciales.
/// - Parameters:
///   - assistantId: ID del asistente asociado al thread. Requerido para asociar el thread con un asistente específico.
///   - messages: Un array opcional de mensajes para iniciar el thread. Cada mensaje debe especificar el rol ('user' o 'system') y el contenido.
///   - metadata: Metadata opcional para asociar con el thread.
/// - Returns: Nada, pero imprime el resultado de la operación a la consola.
func createThread(assistantId: String? = nil, messages: [Message]? = nil, metadata: [String: String]? = nil) {
    let url = URL(string: "https://api.openai.com/v1/beta/threads")! // URL del endpoint para crear threads
    var request = URLRequest(url: url)
    request.httpMethod = "POST" // Uso del método POST para crear un nuevo recurso
    request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type") // El contenido de la solicitud es JSON

    var body: [String: Any] = [:] // Diccionario para construir el cuerpo JSON de la solicitud
    if let assistantId = assistantId {
        body["assistant_id"] = assistantId // Añade el ID del asistente si está presente
    }
    if let messages = messages {
        body["messages"] = messages.map { ["role": $0.role, "content": $0.content] } // Añade mensajes si están presentes
    }
    if let metadata = metadata {
        body["metadata"] = metadata // Añade metadata si está presente
    }

    request.httpBody = try? JSONSerialization.data(withJSONObject: body) // Serializa el cuerpo a JSON

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Error creating thread: \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            do {
                let jsonResponse = try JSONDecoder().decode(Thread.self, from: data)
                print("Thread Created: \(jsonResponse)")
            } catch {
                print("Failed to decode response: \(error)")
            }
        } else {
            print("HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
    }

    task.resume() // Inicia la tarea de red
}



/// Al manejar fechas como timestamps Unix, te aseguras de que el formato sea independiente del huso horario y consistente a través de diferentes sistemas, lo que es especialmente útil para aplicaciones distribuidas globalmente o para cuando los servidores y clientes operan en múltiples zonas horarias.
func convertUnixTimestampToDate(timestamp: Int) -> Date {
    return Date(timeIntervalSince1970: TimeInterval(timestamp))
}



/// Función para recuperar detalles de un thread específico utilizando su ID.
/// - Parameter threadId: ID del thread a recuperar. La URL para recuperar un thread se construye dinámicamente usando el ID del thread. Esto asegura que cada llamada a getThread esté dirigida al thread correcto.
/// Se controla el código de estado HTTP para asegurar que la solicitud fue exitosa (código 200).
func getThread(threadId: String) {
    let urlString = "https://api.openai.com/v1/beta/threads/\(threadId)" // URL del endpoint para obtener un thread específico
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET" // Método HTTP GET para recuperar información
    request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization") // Autenticación utilizando Bearer token

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Error fetching thread details: \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            do {
                // Intenta decodificar la respuesta JSON en un objeto Thread.
                let jsonResponse = try JSONDecoder().decode(Thread.self, from: data)
                if let timestamp = jsonResponse.created_at {
                    let date = convertUnixTimestampToDate(timestamp: timestamp)
                    print("Thread Created Date: \(date)")
                }
                print("Thread Details: \(jsonResponse)")
            } catch {
                print("Failed to decode response: \(error)")
            }
        } else {
            print("HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
    }

    task.resume() // Inicia la tarea de red
}



