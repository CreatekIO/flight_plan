import "@hotwired/turbo-rails";
import { Application, Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

const stimulus = Application.start();

class SortableController extends Controller {

  static targets = ['draggable']
    connect(){
      new Sortable(this.element, { draggable: '[data-sortable-target=draggable]' })
    }

 }

 stimulus.register('sortable', SortableController)