/**Barra de navegacion principal basada em Bootstrap para fresh Style.
 * Gestiona la identidad de marca, los enlaces de navegacion segun el rol del usuario 
* ("cliente", "empleado" o "administrador") sin incluir carrito de compras y las acciones de 
* sesion (registrarse, iniciar sesion o cerrar sesion) adaptandose a pantallas moviles 
* y de escritorio
 */
function Navbar({
    usuario = null,
    onNavigate,
    onAbrirLogin,
    onAbrirRegistro,    
    onCerrarSesion,
}) {
    const rol = (usuario?.rol || '').toLowerCase();

    const irA = (e, ruta) => { //definir una función de navegación
        e.preventDefault();
        onNavigate.(ruta);
    };

    return(
        <nav className="navbar navbar-expand-lg navbar-light bg-light border-bottom sticky top">

    )
}