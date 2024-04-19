//
//  AssistantManager.swift
//  ChatGPT
//
//  Created by Jose Miguel Torres Chavez Nava on 17/04/24.
//

import Foundation

// Definimos una estructura para representar un asistente, conforme al protocolo Codable para facilitar la codificación y decodificación de JSON.
struct Assistant: Codable {
    var id: String?
    var model: String?
    var name: String?
    var description: String?
    var instructions: String?
    var tools: [Tool]?             // Herramientas habilitadas para el asistente.
    var created_at: Date?          // Fecha y hora de la creación del asistente.
    var metadata: [String: String]? // Metadatos adicionales asociados con el asistente.
    var temperature: Double?        // Qué tan aleatoria o determinista debería ser la respuesta.
    var top_p: Double?              // Top p sampling para controlar la aleatoriedad.
    var response_format: String?    // Formato de respuesta esperado (puede ser "text", "json", etc.).
}

// Definimos una estructura para representar las herramientas que se pueden utilizar con el asistente.
struct Tool: Codable {
    let type: String // El tipo de herramienta, por ejemplo, 'file_search'.
}

// Definimos una estructura para los recursos que utilizan las herramientas.
struct ToolResources: Codable {
    let vector_store_ids: [String] // Los IDs de almacenes de vectores para la búsqueda de archivos.
}

// Definimos una estructura para los datos de la solicitud del asistente.
struct AssistantRequest: Codable {
    let model: String
    let name: String
    let instructions: String
    let tools: [Tool]
    let tool_resources: [String: ToolResources]
    var temperature: Double?        // Qué tan aleatoria o determinista debería ser la respuesta.
    var top_p: Double?              // Top p sampling para controlar la aleatoriedad.
    var response_format: String?    // Formato de respuesta esperado.
}


/// Función para crear un asistente en la API de OpenAI. Esta función se utiliza cada vez que necesites registrar un nuevo asistente con características específicas en tu cuenta de OpenAI:
/// Utiliza createAssistant() cuando quieras configurar un nuevo asistente con instrucciones específicas y herramientas. Esto normalmente se hace durante el desarrollo inicial de tu aplicación o cuando decides expandir la funcionalidad de tu app con nuevos asistentes.
/// Generalmente, esta función se llama una vez para cada tipo de asistente que necesitas en tu aplicación, a menos que necesites actualizar o reconfigurar los asistentes existentes.
func createAssistant() {
    let url = URL(string: "https://api.openai.com/v1/beta/assistants")! // Define la URL de la API.
    var request = URLRequest(url: url) // Crea un objeto URLRequest con la URL.
    request.httpMethod = "POST" // Establece el método HTTP como POST.
    request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization") // Agrega el token de autenticación en los headers.
    request.addValue("application/json", forHTTPHeaderField: "Content-Type") // Indica que el contenido de la solicitud es JSON.

    // Prepara el cuerpo de la solicitud con los detalles del asistente.
    let assistantBody = AssistantRequest(
        model: "gpt-4-turbo",
        name: "Assistant cool name",
        instructions: "You are an language instructor bot, and you have access to files to build realistic phrases and deliver the results in JSON format.",
        tools: [Tool(type: "file_search")],
        tool_resources: ["file_search": ToolResources(vector_store_ids: ["vs_123"])]
    )

    // Intenta codificar el cuerpo de la solicitud en JSON.
    do {
        request.httpBody = try JSONEncoder().encode(assistantBody)
    } catch {
        print("Error encoding request body: \(error)") // Captura y muestra cualquier error durante la codificación.
        return
    }

    // Crea y comienza una tarea de URLSession para enviar la solicitud.
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Error: \(error?.localizedDescription ?? "Unknown error")") // Gestiona errores de conexión.
            return
        }

        // Verifica el código de estado HTTP de la respuesta.
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            do {
                // Intenta decodificar la respuesta JSON en un objeto Assistant.
                let jsonResponse = try JSONDecoder().decode(Assistant.self, from: data)
                print("Assistant Created: \(jsonResponse)") // Muestra la respuesta decodificada.
            } catch {
                print("Failed to decode response: \(error)") // Muestra errores de decodificación.
            }
        } else {
            print("HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)") // Muestra el código de estado HTTP si no es 200.
        }
    }

    task.resume() // Reanuda la tarea de red si se había suspendido temporalmente.
}



/// Función que permite obtener una lista de todos los asistentes que has creado. Esto es útil para la gestión y el mantenimiento de los asistentes, especialmente en un entorno de producción donde puede que no tengas un seguimiento detallado de cada asistente configurado durante el desarrollo.
/// Esta función se llama cuando se necesite hacer una auditoría de los asistentes disponibles, verificar sus configuraciones o cuando se solucionen problemas relacionados con uno o más asistentes.
/// No se necesita llamar a esta función con mucha frecuencia. No es necesaria para el funcionamiento diario de los asistentes de la aplicación.
func listAssistants() {
    let url = URL(string: "https://api.openai.com/v1/beta/assistants")! // URL del endpoint para listar asistentes
    var request = URLRequest(url: url)
    request.httpMethod = "GET" // Método HTTP GET
    request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization") // Agrega el token de autenticación

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Error fetching assistants: \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            do {
                // Asumimos que la respuesta es un JSON y la decodificamos
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Assistants: \(jsonResponse)")
                }
            } catch {
                print("Failed to decode response: \(error)")
            }
        } else {
            print("HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
    }

    task.resume()
}


/// Función para recuperar detalles de un asistente específico utilizando su ID, algunos ejemplos de uso son:
/// **Auditoría y Monitoreo:** Cuando necesitas asegurarte de que los asistentes están configurados correctamente y cumplen con las expectativas.
/// **Operaciones Dinámicas:** En un entorno donde los asistentes pueden cambiar o actualizarse con frecuencia, usar esta función te permite recuperar la configuración más reciente antes de interactuar con el asistente.
/// **Soporte y Mantenimiento:** Cuando estás solucionando problemas o proporcionando soporte técnico, es esencial poder consultar rápidamente los detalles de un asistente específico.
func getAssistant(assistantId: String) {
    let urlString = "https://api.openai.com/v1/beta/assistants/\(assistantId)" // URL del endpoint para obtener un asistente específico
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET" // Método HTTP GET
    request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization") // Agrega el token de autenticación

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Error fetching assistant details: \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            do {
                // Intenta decodificar la respuesta JSON en un objeto Assistant.
                let jsonResponse = try JSONDecoder().decode(Assistant.self, from: data)
                print("Assistant Details: \(jsonResponse)") // Muestra los detalles del asistente recuperado.
            } catch {
                print("Failed to decode response: \(error)") // Muestra errores de decodificación.
            }
        } else {
            print("HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)") // Muestra el código de estado HTTP si no es 200.
        }
    }

    task.resume() // Reanuda la tarea de red si se había suspendido temporalmente.
}



/// Función para modificar un asistente existente en la API de OpenAI.
/// Se utiliza para actualizar propiedades como el nombre, instrucciones, herramientas, entre otros.
/// Esta función es útil cuando necesitas cambiar la configuración de un asistente existente sin necesidad de crear uno nuevo.
func modifyAssistant(assistantId: String, updatedAssistant: AssistantRequest) {
    let urlString = "https://api.openai.com/v1/beta/assistants/\(assistantId)" // URL del endpoint para modificar un asistente específico
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "PATCH" // Método HTTP PATCH para actualizar recursos
    request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization") // Agrega el token de autenticación
    request.addValue("application/json", forHTTPHeaderField: "Content-Type") // Indica que el contenido de la solicitud es JSON

    // Intenta codificar el cuerpo de la solicitud con los detalles actualizados del asistente.
    do {
        request.httpBody = try JSONEncoder().encode(updatedAssistant)
    } catch {
        print("Error encoding request body: \(error)") // Captura y muestra cualquier error durante la codificación.
        return
    }

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Error modifying assistant: \(error?.localizedDescription ?? "Unknown error")") // Gestiona errores de conexión.
            return
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            do {
                // Intenta decodificar la respuesta JSON en un objeto Assistant.
                let jsonResponse = try JSONDecoder().decode(Assistant.self, from: data)
                print("Assistant Modified: \(jsonResponse)") // Muestra la respuesta decodificada.
            } catch {
                print("Failed to decode response: \(error)") // Muestra errores de decodificación.
            }
        } else {
            print("HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)") // Muestra el código de estado HTTP si no es 200.
        }
    }

    task.resume() // Reanuda la tarea de red si se había suspendido temporalmente.
}



/// Función para eliminar un asistente específico en la API de OpenAI.
/// Utiliza esta función cuando un asistente ya no es necesario o para limpiar asistentes de prueba.
func deleteAssistant(assistantId: String) {
    let urlString = "https://api.openai.com/v1/beta/assistants/\(assistantId)" // URL del endpoint para eliminar un asistente específico
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "DELETE" // Método HTTP DELETE para eliminar recursos
    request.addValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization") // Agrega el token de autenticación

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error deleting assistant: \(error.localizedDescription)") // Gestiona errores de conexión.
            return
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
            print("Assistant Deleted Successfully") // Confirma que el asistente fue eliminado exitosamente.
        } else {
            print("HTTP Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)") // Muestra el código de estado HTTP si no es 204.
        }
    }

    task.resume() // Reanuda la tarea de red si se había suspendido temporalmente.
}


