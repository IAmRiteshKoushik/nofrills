import axios, { type AxiosRequestConfig } from 'axios'

export const apiClient = axios.create({
  baseURL: 'http://localhost:8080',
})

export const apiRequest = <T>(config: AxiosRequestConfig, options?: AxiosRequestConfig): Promise<T> =>
  apiClient({ ...config, ...options }).then(({ data }) => data)
