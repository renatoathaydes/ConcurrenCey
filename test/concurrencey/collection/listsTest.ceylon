import ceylon.collection {
    LinkedList
}
import ceylon.test {
    test,
    assertEquals
}


class ObservableLinkedListTest() {

	value list = ObservableLinkedList<String>();

	shared test void observerNotifiedOnAdd() {
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);

		list.add("Hi");

		assert(is AddEvent<String> final = result);
		assertEquals(final.indexes, [0]);
		assertEquals(final.elements, ["Hi"]);
		assertEquals(list, ["Hi"]);
	}

	shared test void observerNotifiedOnAddAll() {
		list.add("Hi");
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);

		list.addAll({"B", "C"});

		assert(is AddEvent<String> final = result);
		assertEquals(final.indexes, [1, 2]);
		assertEquals(final.elements, ["B", "C"]);
		assertEquals(list, ["Hi", "B", "C"]);
	}

	shared test void observerNotifiedOnClear() {
		list.addAll({"A", "B", "C"});
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);

		list.clear();

		assert(is RemoveEvent<String> final = result);
		assertEquals(final.indexes, [0, 1, 2]);
		assertEquals(final.elements, ["A", "B", "C"]);
		assertEquals(list, []);
	}

	shared test void observerNotifiedOnInsert() {
		list.addAll({"A", "B", "C"});
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);

		list.insert(2, "M");

		assert(is AddEvent<String> final = result);
		assertEquals(final.indexes, [2]);
		assertEquals(final.elements, ["M"]);
		assertEquals(list, ["A", "B", "M", "C"]);
	}

	shared test void observerNotifiedOnDelete() {
		list.addAll({"A", "B", "C", "D"});
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);

		value returned = list.delete(2);

		assert(is RemoveEvent<String> final = result);
		assertEquals(final.indexes, [2]);
		assertEquals(final.elements, ["C"]);
		assertEquals(returned, "C");
		assertEquals(list, ["A", "B", "D"]);
	}

	shared test void observerNotifiedOnRemoveElement() {
		value list = ObservableLinkedList({"A", "B", "A", "A", "C"});
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);

		list.remove("A");

		assert(is RemoveEvent<String> final = result);
		assertEquals(final.indexes, [0, 2, 3]);
		assertEquals(final.elements, ["A", "A", "A"]);
		assertEquals(list, ["B", "C"]);
	}

	shared test void observerNotifiedOnSet() {
		list.addAll({"A", "B"});
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);

		list.set(1, "C");

		assert(is ReplaceEvent<String> final = result);
		assertEquals(final.index, 1);
		assertEquals(final.element, "C");
		assertEquals(list, ["A", "C"]);
	}

	shared test void notNotifiedWhenRemoveElementDoesNotModifyList() {
		value list = ObservableLinkedList<String>();
		list.addAll({"A", "B"});
		variable Integer count = 0;
		list.observe((ListEvent<String>|Exception e) => count++);

		list.remove("C");

		assertEquals(count, 0);
	}

	shared test void observerNotifiedOnDeleteMeasure() {
		list.addAll({"A", "B", "C", "D", "E", "F"});
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);

		list.deleteMeasure(2, 3);

		assert(is RemoveEvent<String> final = result);
		assertEquals(final.indexes, 2..4);
		assertEquals(final.elements, ["C", "D", "E"]);
		assertEquals(list, ["A", "B", "F"]);

		list.deleteMeasure(1, 5);

		assert(is RemoveEvent<String> final2 = result);
		assertEquals(final2.indexes, [1, 2]);
		assertEquals(final2.elements, ["B", "F"]);
		assertEquals(list, ["A"]);
	}

	shared test void notNotifiedWhenDeleteMeasureDoesNotModifyList() {
		list.addAll({"A", "B", "C", "D", "E"});
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);

		list.deleteMeasure(10, 3);

		assert(is Exception final = result);
		assertEquals(list, ["A", "B", "C", "D", "E"]);
	}

	shared test void deleteSpanShouldWorkAsInLinkedList() {
		list.addAll({"A", "B", "C", "D", "E"});
		variable ListEvent<String>|Exception result = Exception();
		list.observe((ListEvent<String>|Exception e) => result = e);

		list.deleteSpan(2, 3);

		assert(is RemoveEvent<String> final = result);
		assertEquals(final.indexes, 2..3);
		assertEquals(final.elements, ["C", "D"]);
		assertEquals(list, ["A", "B", "E"]);
	}

	shared test void linkedListTests() {
		value l = LinkedList({ "A", "B", "C", "D", "E", "F", "G"});
		l.deleteMeasure(2, 3);
		assertEquals(l, LinkedList({"A", "B", "F", "G"}));
	}

}