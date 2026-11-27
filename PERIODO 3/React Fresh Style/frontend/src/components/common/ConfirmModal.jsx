/**
 * Modal de confirmación reutilizable basado en Bootstrap para Fresh Style.
 * Controla desde el componente padre si se muestra ("mostrar") y qué ocurre al
 * confirmar ("onConfirmar") o cancelar ("onCancelar"), evitando clics accidentales
 * antes de cambiar estados en reservas, establecimientos, empleados o servicios.
 */
function ConfirmModal({ mostrar, titulo, mensaje, onConfirmar, onCancelar }) {
  if (!mostrar) return null;

  return (
    <>
      <div className="modal-backdrop fade show"></div>

      <div className="modal fade show" style={{ display: 'block' }} tabIndex="-1">
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content">
            <div className="modal-header">
              <h5 className="modal-title">{titulo}</h5>
              <button type="button" className="btn-close" onClick={onCancelar}></button>
            </div>
            <div className="modal-body">
              <p className="mb-0">{mensaje}</p>
            </div>
            <div className="modal-footer">
              <button type="button" className="btn btn-secondary" onClick={onCancelar}>
                Cancelar
              </button>
              <button type="button" className="btn btn-primary" onClick={onConfirmar}>
                Confirmar
              </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

export default ConfirmModal;
