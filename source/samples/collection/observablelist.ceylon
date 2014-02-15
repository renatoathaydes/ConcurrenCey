import concurrencey.collection { ObservableLinkedList, ListEvent, AddEvent, RemoveEvent, ReplaceEvent }


void runObservableList() {
	value list = ObservableLinkedList<String>();
	list.observe(void(Exception|ListEvent<String> event) {
		switch(event)
		case (is AddEvent<String>) { print("Added ``event.elements``"); }
		case (is RemoveEvent<String>) { print("Removed ``event.elements``"); }
		case (is ReplaceEvent<String>) { print("Replaced index ``event.index`` with ``event.element``"); }
		case (is Exception) { throw event; }
	});
	
	list.add("Added value");
	list.addAll({"1", "2", "3"});
	list.remove(0);
	list.set(1, "ABC");
}