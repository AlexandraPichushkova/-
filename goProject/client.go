package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"golang.org/x/time/rate"
)

var (
	outputMutex    sync.Mutex              // Мьютекс для синхронизации вывода в консоль
	clientLimiter  = rate.NewLimiter(5, 5) // 5 запросов в секунду, с burst = 5
	requestMutex   sync.Mutex              //Мьютекс для синхронизации запросов
	clientCounters = make(map[int]int)     // Счетчики запросов для каждого  (ключ — ID клиента, значение — количество запросов)
	counterMutex   sync.Mutex              // Мьютекс для синхронизации доступа к счетчикам клиентов
)

func main() {
	fmt.Println("Клиент запущен")
	var wg sync.WaitGroup //ожидание завершения всех горутин

	wg.Add(1)
	go func() {
		defer wg.Done()
		fmt.Println("Первый клиент запущен")
		runClient(1, "http://localhost:8081", 100)
	}()

	wg.Add(1)
	go func() {
		defer wg.Done()
		fmt.Println("Второй клиент запущен")
		runClient(2, "http://localhost:8081", 100)
	}()

	wg.Add(1)
	go func() {
		defer wg.Done()
		fmt.Println("Третий клиент запущен")
		checkServerStatus("http://localhost:8081")
	}()

	wg.Wait()
}

// Функция для запуска клиента с воркерами
func runClient(clientID int, url string, totalRequests int) {
	var wg sync.WaitGroup

	// Количество воркеров для каждого клиента
	workers := 2

	// Количество запросов на каждого воркера
	requestsPerWorker := totalRequests / workers

	// Создаем map для сбора статистики по статусам
	statusStats := make(map[int]int)
	var statsMutex sync.Mutex // Мьютекс для безопасного доступа к map

	// Запуск воркеров
	for i := 1; i <= workers; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			fmt.Printf("Клиент %d воркер %d запущен\n", clientID, workerID)
			sendRequests(clientID, url, requestsPerWorker, workerID, &statusStats, &statsMutex)
		}(i)
	}

	wg.Wait()

	// Синхронизация вывода статистики
	outputMutex.Lock()
	defer outputMutex.Unlock()

	// Вывод статистики по завершению работы клиента
	fmt.Printf("Клиент %d завершен. Статистика:\n", clientID)
	fmt.Printf("Отправлено запросов: %d\n", totalRequests)
	fmt.Println("Разбивка по статусам:")
	for status, count := range statusStats {
		fmt.Printf(" %d %d - %d\n", clientID, status, count)
	}
}

func sendRequests(clientID int, url string, requests int, workerID int, statusStats *map[int]int, statsMutex *sync.Mutex) {
	for i := 0; i < requests; i++ {
		requestMutex.Lock() // Блокируем доступ для других воркеров

		// Увеличиваем счетчик запросов для клиента
		counterMutex.Lock()
		clientCounters[clientID]++
		requestNumber := clientCounters[clientID]
		counterMutex.Unlock()

		if !clientLimiter.Allow() { //Проверяем, не превышен ли лимит запросов
			// Увеличиваем счётчик для статуса "лимит превышен"
			statsMutex.Lock()
			(*statusStats)[429]++ // 429 - статус "лимит превышен"
			statsMutex.Unlock()

			log.Printf("Клиент %d воркер %d: Лимит запросов превышен\n", clientID, workerID)
			requestMutex.Unlock()
			continue
		}
		// Создаем POST-запрос с указанием ID клиента в заголовке
		req, err := http.NewRequest(http.MethodPost, url, strings.NewReader(fmt.Sprintf("Запрос от клиента %d воркера %d", clientID, workerID)))
		if err != nil {
			log.Printf("Воркер %d: Ошибка при создании запроса %d: %v\n", workerID, requestNumber, err)
			requestMutex.Unlock()
			continue
		}
		req.Header.Set("X-Client-ID", strconv.Itoa(clientID)) // Указываем ID клиента

		// Отправляем запрос на сервер
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			log.Printf("Воркер %d: Ошибка при отправке запроса %d: %v\n", workerID, requestNumber, err)
			requestMutex.Unlock()
			continue
		}
		defer resp.Body.Close()

		// Чтение тела ответа
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Printf("Клиент %d воркер %d: Ошибка при чтении ответа %d: %v\n", clientID, workerID, requestNumber, err)
			requestMutex.Unlock()
			continue
		}

		response := strings.TrimRight(string(body), "\n") // Удаляем только символы новой строки
		fmt.Printf("Клиент %d воркер %d: Запрос %d отправлен. Ответ сервера: %s.\n", clientID, workerID, requestNumber, response)

		// Обновляем статистику по статусам
		statsMutex.Lock()
		(*statusStats)[resp.StatusCode]++
		statsMutex.Unlock()

		// Задержка между запросами
		time.Sleep(200 * time.Millisecond)
		requestMutex.Unlock()
	}
}

func checkServerStatus(url string) {
	for {
		resp, err := http.Get(url) //Отправляем GET-запрос на сервер
		if err != nil {
			log.Printf("Сервер недоступен: %v\n", err)
		} else {
			defer resp.Body.Close()

			// Чтение тела ответа
			body, err := io.ReadAll(resp.Body) //Читаем тело ответа
			if err != nil {
				log.Printf("Ошибка при чтении ответа: %v\n", err)
			} else {
				fmt.Printf("Сервер доступен. Ответ: %s. Статус: %d\n", string(body), resp.StatusCode)
			}
		}
		time.Sleep(5 * time.Second) //Задержка между проверками 5 секунд
	}
}
