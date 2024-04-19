//
//  MessageManager.swift
//  ChatGPT
//
//  Created by Jose Miguel Torres Chavez Nava on 18/04/24.
//

import Foundation

struct MessageContent: Codable {
    let type: String
    let text: TextContent
}

struct TextContent: Codable {
    let value: String
    let annotations: [String]  // Asumiendo que las anotaciones son una lista de strings, ajustar según la API.
}

struct MessageResponse: Codable {
    var id: String?
    var object: String?
    var created_at: Int?
    var assistant_id: String?
    var thread_id: String?
    var run_id: String?
    var role: String?
    var content: [MessageContent]
    var attachments: [String]  // Asumiendo que los adjuntos son una lista de strings, ajustar según la API.
    var metadata: [String: String]?
}


/// Función para crear un mensaje en un thread específico en la API de OpenAI.
/// - Parameters:
///   - threadId: ID del thread donde se creará el mensaje.
///   - role: El rol del creador del mensaje ('user' o 'system').
///   - content: El contenido del mensaje a enviar.
/// - Returns: Nada, pero imprime el resultado de la operación a la consola.
func createMessage(threadId: String, role: String, content: String) {
    let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/messages")! // URL del endpoint para crear mensajes
    var request = URLRequest(url: url)
    request.httpMethod = "POST" // Uso del método POST para crear un nuevo recurso
    request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type") // El contenido de la solicitud es JSON

    let messageContent = MessageContent(type: "text", text: TextContent(value: content, annotations: []))
    let body: [String: Any] = [
        "role": role,
        "content": [
            [
                "type": messageContent.type,
                "text": ["value": messageContent.text.value, "annotations": messageContent.text.annotations]
            ]
        ]
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: body) // Serializa el cuerpo a JSON

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Error creating message: \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            do {
                let jsonResponse = try JSONDecoder().decode(MessageResponse.self, from: data)
                print("Message Created: \(jsonResponse)")
            } catch {
                print("Failed to decode response: \(error)")
            }
        } else {
            print("HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
    }

    task.resume() // Inicia la tarea de red
}


