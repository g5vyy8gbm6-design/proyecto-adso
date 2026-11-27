/**
 * Configura una instabncia centralizada de Axios para comunicarce con la api REST de fresh style
 *Inyectar automaticamente el token JWT en cada peticion saliente
 */

import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api';

const axiosClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  }
});

//Interceptor de peticion: inyecta el token JWT si el usuario inicio sesion 
axiosClient.interceptors.request.use((config) => {
    const token = localStorage.getItem('fs_token');
  if (token) {
    config.headers.Authorization = 'Bearer ${token}';
  }
  return config;
});

export default axiosClient;