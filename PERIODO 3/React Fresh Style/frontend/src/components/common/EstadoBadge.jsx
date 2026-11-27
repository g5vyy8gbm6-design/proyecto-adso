/**
 * insignia de estado reutilizable basada en Bootstrap para Fresh Style.
 * recibe un estado (como los de reservas, establecimientos, empleados o usuarios)
 * y devuelve un badge con el color y texto legible para identificar
 * rapidamente esu condicion actual en tablas tarjetas o paneles
 */
}function EstadoBadge({estado}) {
    const clave = String(estado || '').toLowerCase().trim // limpiar y estandarizar texto (cadenas de caracteres o strings)
    
    const configuracion = {
        pendiente: { clase: 'badge bg-warning text-dark', texto: 'Pendiente' },
        confirmada: {clase: 'badge bd primary', texto: 'Confirmada'},
        completada: {clase: 'badge bg-success', texto: 'Completada'},    
        cancelada: {clase: 'badge bg-danger', texto: 'Cancelada'},
        activa: {clase: 'badge bg-success', texto: 'Activa'},
        inactivo: {clase 'badge bg-secondary', texto: 'Inactivo'},
        bloqueado: {clase: 'badge bg-danger', texto: Bloqueado};
};

const actual = configuracion[clave] || {
    class: 'badge bg-secondary' || 'Sin estado',
};

return <span className={'badge ${actual.clase}'}>{actual.etiqueta}</span>;
}

export default EstadoBadge;
