package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"sync"
	"time"

	"github.com/joho/godotenv"
	"golang.org/x/time/rate"
)

type Stats struct {
	TotalRequests     int            `json:"total_requests"`
	PositiveResponses int            `json:"positive_responses"`
	NegativeResponses int            `json:"negative_responses"`
	ClientStats       map[int]Client `json:"client_stats"` //Статистика по каждому клиенту (ключ — ID клиента, значение — структура Client)
}

type Client struct {
	TotalRequests     int `json:"total_requests"`
	PositiveResponses int `json:"positive_responses"`
	NegativeResponses int `json:"negative_responses"`
}

var (
	stats     Stats                   //Структура, хранящая статистику по запросам
	statsLock sync.Mutex              //Мьютекс для синхронизации доступа к stats
	limiter   = rate.NewLimiter(5, 5) // 5 запросов в секунду, с burst = 5
)

func init() {
	stats = Stats{
		ClientStats: make(map[int]Client),
	}
}

func main() {
	// Инициализация генератора случайных чисел
	rand.Seed(time.Now().UnixNano())

	// Загрузка переменных окружения из файла .env
	err := godotenv.Load()
	if err != nil {
		log.Printf("Ошибка загрузки файла .env: %v\n", err)
	}

	// Чтение порта из переменной окружения
	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8081" // Порт по умолчанию
		log.Println("Используется порт по умолчанию:", port)
	}

	http.HandleFunc("/", handleRequest)       //Обработчик для всех запросов
	http.HandleFunc("/stats", handleGetStats) // Обработчик для получения статистики

	log.Printf("Сервер запущен на порту %s\n", port)
	log.Fatal(http.ListenAndServe(":"+port, nil)) // Запуск сервера
}

func handleRequest(w http.ResponseWriter, r *http.Request) { //Основной обработчик запросов
	if !limiter.Allow() { //Проверяем, не превышен ли лимит запросов
		http.Error(w, "Лимит запросов превышен", http.StatusTooManyRequests)
		return
	}
	log.Printf("Получен запрос: %s %s\n", r.Method, r.URL.Path)
	switch r.Method {
	case http.MethodGet:
		handleGet(w, r)
	case http.MethodPost:
		handlePost(w, r)
	default:
		http.Error(w, "Метод не поддерживается", http.StatusMethodNotAllowed)
	}
}

// Обрабатывает GET-запросы
func handleGet(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "GET запрос получен")
}

// Возвращает статистику в формате JSON
func handleGetStats(w http.ResponseWriter, r *http.Request) {
	statsLock.Lock() //Блокирует мьютекс для безопасного доступа к stats
	defer statsLock.Unlock()

	w.Header().Set("Content-Type", "application/json") // Устанавливаем заголовок Content-Type

	// Кодируем статистику в JSON
	if err := json.NewEncoder(w).Encode(stats); err != nil {
		http.Error(w, "Ошибка при кодировании статистики", http.StatusInternalServerError)
		return
	}
}

// Обрабатывает POST-запросы, обновляет статистику и возвращает случайный статус
func handlePost(w http.ResponseWriter, r *http.Request) {
	clientIDStr := r.Header.Get("X-Client-ID")
	if clientIDStr == "" {
		http.Error(w, "Заголовок X-Client-ID отсутствует", http.StatusBadRequest)
		return
	}

	// Генерация случайного статуса
	status := getRandomStatus()
	w.WriteHeader(status)

	isPositive := status == http.StatusOK || status == http.StatusAccepted

	clientID := 0
	if idStr := r.Header.Get("X-Client-ID"); idStr != "" {
		if id, err := strconv.Atoi(idStr); err == nil {
			clientID = id
		}
	}

	statsLock.Lock()
	defer statsLock.Unlock()

	stats.TotalRequests++ //Увеличиваем общее количество запросов
	if isPositive {
		stats.PositiveResponses++
	} else {
		stats.NegativeResponses++
	}

	client := stats.ClientStats[clientID]
	client.TotalRequests++
	//Увеличиваем количество успешных или неудачных ответов
	if isPositive {
		client.PositiveResponses++
	} else {
		client.NegativeResponses++
	}
	stats.ClientStats[clientID] = client

	// Логируем статус и ID клиента
	log.Printf("Отправлен статус: %d (клиент %d)\n", status, clientID)

	// Отправляем ответ клиенту
	switch status {
	case http.StatusOK, http.StatusAccepted:
		fmt.Fprintf(w, "Успешный запрос. Статус: %d", status)
	case http.StatusBadRequest, http.StatusInternalServerError:
		fmt.Fprintf(w, "Ошибка. Статус: %d", status)
	}
}

// Функция для получения случайного статуса
func getRandomStatus() int {
	// Генерация случайного числа от 0 до 99
	randomValue := rand.Intn(100)

	// 70% положительных ответов, 30% отрицательных
	if randomValue < 70 {
		// Положительные статусы
		positiveStatuses := []int{http.StatusOK, http.StatusAccepted}
		return positiveStatuses[rand.Intn(len(positiveStatuses))]
	} else {
		// Отрицательные статусы
		negativeStatuses := []int{http.StatusBadRequest, http.StatusInternalServerError}
		return negativeStatuses[rand.Intn(len(negativeStatuses))]
	}
}
